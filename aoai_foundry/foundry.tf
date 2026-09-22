data "azurerm_client_config" "current" {}

locals {
  foundry_name = coalesce(
    var.foundry_name,
    "foundry-retirement-${substr(sha256(data.azurerm_client_config.current.subscription_id), 0, 8)}"
  )
}

resource "azurerm_resource_group" "foundry" {
  name     = var.resource_group_name
  location = var.location
}

# 最初から公開アクセスを無効にした状態で Foundry 本体を作成する。
resource "azurerm_cognitive_account" "foundry" {
  name                = local.foundry_name
  resource_group_name = azurerm_resource_group.foundry.name
  location            = azurerm_resource_group.foundry.location
  kind                = "AIServices"
  sku_name            = "S0"

  custom_subdomain_name         = local.foundry_name
  project_management_enabled    = true
  public_network_access_enabled = false
  local_auth_enabled            = false

  network_acls {
    default_action = "Deny"
    bypass         = "None"
    ip_rules       = []
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    purpose = "model-retirement-check"
  }
}

resource "azurerm_cognitive_account_project" "inspection" {
  name                 = var.project_name
  display_name         = "Model retirement check"
  description          = "Foundry の画面でモデルの終了日を確認するためのプロジェクト。"
  cognitive_account_id = azurerm_cognitive_account.foundry.id
  location             = azurerm_cognitive_account.foundry.location

  identity {
    type = "SystemAssigned"
  }
}
