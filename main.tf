locals {
  openai_name = "${var.name_prefix}-openai"
  apim_name   = "${var.name_prefix}-apim"

  # AOAI データプレーンのエンドポイント。
  # リソース属性ではなく決定的な名前（custom_subdomain_name）から組み立てる。
  openai_endpoint = "https://${local.openai_name}.openai.azure.com"
}

resource "azurerm_resource_group" "main" {
  name     = "${var.name_prefix}-rg"
  location = var.location
  tags     = var.tags
}

# ネットワーク（VNet / サブネット / NSG / Public IP / Private DNS Zone）。
module "network" {
  source = "./modules/network"

  name_prefix         = var.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  vnet_address_space  = var.vnet_address_space
  apim_subnet_prefix  = var.apim_subnet_prefix
  pe_subnet_prefix    = var.pe_subnet_prefix
  tags                = var.tags
}

# トークン使用量などのメトリクス / ログの送信先。
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.name_prefix}-law"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

resource "azurerm_application_insights" "main" {
  name                = "${var.name_prefix}-appi"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
  tags                = var.tags
}

# APIM（別モジュール）。External VNet injection で VNet に載せる。
# ゲートウェイは public のまま、アウトバウンドは VNet 経由で AOAI の PE に到達する。
module "apim" {
  source = "./modules/apim"

  name                 = local.apim_name
  resource_group_name  = azurerm_resource_group.main.name
  location             = var.location
  sku_name             = var.apim_sku_name
  publisher_name       = var.apim_publisher_name
  publisher_email      = var.apim_publisher_email
  aoai_endpoint        = local.openai_endpoint
  subnet_id            = module.network.apim_subnet_id
  public_ip_address_id = module.network.apim_public_ip_id

  # トークン使用量メトリクスの送信先 Application Insights。
  application_insights_id                  = azurerm_application_insights.main.id
  application_insights_instrumentation_key = azurerm_application_insights.main.instrumentation_key

  tags = var.tags
}

# Azure OpenAI アカウント。public アクセスを無効化し、Private Endpoint 経由のみ許可。
resource "azurerm_cognitive_account" "openai" {
  name                  = local.openai_name
  resource_group_name   = azurerm_resource_group.main.name
  location              = var.location
  kind                  = "OpenAI"
  sku_name              = var.aoai_sku_name
  custom_subdomain_name = local.openai_name

  # インターネットからの直接アクセスを無効化。アクセスは Private Endpoint 経由のみ。
  public_network_access_enabled = false

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

resource "azurerm_cognitive_deployment" "gpt" {
  name                 = var.aoai_deployment_name
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = var.aoai_model_name
    version = var.aoai_model_version
  }

  sku {
    name     = var.aoai_deployment_sku_name
    capacity = var.aoai_deployment_capacity
  }
}

# AOAI の Private Endpoint（VNet 内からの private アクセス用）。
resource "azurerm_private_endpoint" "openai" {
  name                = "${local.openai_name}-pe"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  subnet_id           = module.network.pe_subnet_id

  private_service_connection {
    name                           = "${local.openai_name}-psc"
    private_connection_resource_id = azurerm_cognitive_account.openai.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [module.network.openai_private_dns_zone_id]
  }

  tags = var.tags

  # モデルデプロイ中はアカウントが遷移状態になり PE 作成が 400 で拒否されるため、
  # デプロイ完了を待ってから PE を作成する（初回構築時のレース回避）。
  depends_on = [azurerm_cognitive_deployment.gpt]
}

# APIM のマネージド ID に AOAI の推論呼び出し権限を付与（キーレス認証）。
resource "azurerm_role_assignment" "apim_to_openai" {
  scope                = azurerm_cognitive_account.openai.id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = module.apim.principal_id
}
