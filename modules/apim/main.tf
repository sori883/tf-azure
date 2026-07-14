resource "azurerm_api_management" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = var.sku_name

  # External VNet injection: ゲートウェイは public のまま、アウトバウンドは VNet 経由。
  # これにより同 VNet 内の Private Endpoint 化した AOAI へ到達できる。
  virtual_network_type = "External"
  virtual_network_configuration {
    subnet_id = var.subnet_id
  }
  # stv2 の injection には Standard Public IP が必須。
  public_ip_address_id = var.public_ip_address_id

  # AOAI への認証に使うマネージド ID。
  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

resource "azurerm_api_management_api" "openai" {
  name                  = "azure-openai"
  resource_group_name   = var.resource_group_name
  api_management_name   = azurerm_api_management.this.name
  revision              = "1"
  display_name          = "Azure OpenAI"
  path                  = "openai"
  protocols             = ["https"]
  subscription_required = true
  # Responses API は v1 パス。デプロイ名はリクエストボディの model で指定する。
  service_url = "${var.aoai_endpoint}/openai/v1"
}

# 公開する操作は Responses API のみ。
resource "azurerm_api_management_api_operation" "responses" {
  operation_id        = "responses"
  api_name            = azurerm_api_management_api.openai.name
  api_management_name = azurerm_api_management.this.name
  resource_group_name = var.resource_group_name
  display_name        = "Responses"
  method              = "POST"
  url_template        = "/responses"
  description         = "Azure OpenAI Responses API"
}

# APIM から Application Insights へのロガー（トークンメトリクス / リクエストログの送信先）。
resource "azurerm_api_management_logger" "appinsights" {
  name                = "appinsights"
  api_management_name = azurerm_api_management.this.name
  resource_group_name = var.resource_group_name
  resource_id         = var.application_insights_id

  application_insights {
    instrumentation_key = var.application_insights_instrumentation_key
  }
}

# OpenAI API の Application Insights ログを有効化（llm-emit-token-metric の前提条件）。
resource "azurerm_api_management_api_diagnostic" "openai" {
  identifier               = "applicationinsights"
  resource_group_name      = var.resource_group_name
  api_management_name      = azurerm_api_management.this.name
  api_name                 = azurerm_api_management_api.openai.name
  api_management_logger_id = azurerm_api_management_logger.appinsights.id

  sampling_percentage       = 100
  always_log_errors         = true
  verbosity                 = "information"
  http_correlation_protocol = "W3C"
}

# カスタムメトリクスの有効化（metrics = true）。
# これが無いと llm-emit-token-metric はメトリクスを送信しない。
# azurerm の api_diagnostic リソースは metrics プロパティ未対応のため azapi で補完する。
resource "azapi_update_resource" "openai_diagnostic_metrics" {
  type        = "Microsoft.ApiManagement/service/apis/diagnostics@2022-08-01"
  resource_id = azurerm_api_management_api_diagnostic.openai.id

  body = {
    properties = {
      metrics = true
    }
  }
}

# API レベルポリシー:
#   - authentication-managed-identity で AOAI 用のトークンを取得し Authorization ヘッダを付与
#   - set-backend-service でバックエンドを AOAI エンドポイントに設定
#   - llm-emit-token-metric でトークン使用量（total / prompt / completion）を
#     Application Insights のカスタムメトリクスとして記録（Responses API 対応）
resource "azurerm_api_management_api_policy" "openai" {
  api_name            = azurerm_api_management_api.openai.name
  api_management_name = azurerm_api_management.this.name
  resource_group_name = var.resource_group_name

  xml_content = <<XML
<policies>
  <inbound>
    <base />
    <authentication-managed-identity resource="https://cognitiveservices.azure.com" />
    <set-backend-service base-url="${var.aoai_endpoint}/openai/v1" />
    <llm-emit-token-metric namespace="AzureOpenAI">
      <dimension name="API ID" />
      <dimension name="Operation ID" />
      <dimension name="Subscription ID" />
      <dimension name="Model" value="@(context.Request.Body.As&lt;JObject&gt;(preserveContent: true).Value&lt;string&gt;(&quot;model&quot;) ?? &quot;unknown&quot;)" />
    </llm-emit-token-metric>
  </inbound>
  <backend>
    <base />
  </backend>
  <outbound>
    <base />
  </outbound>
  <on-error>
    <base />
  </on-error>
</policies>
XML

  depends_on = [azurerm_api_management_api_diagnostic.openai]
}

# クライアントが利用する APIM サブスクリプションキー。
resource "azurerm_api_management_subscription" "openai" {
  api_management_name = azurerm_api_management.this.name
  resource_group_name = var.resource_group_name
  display_name        = "azure-openai-subscription"
  # API リソースの id は ";rev=1" 付きで返るが、リビジョン付き scope の
  # サブスクリプションはゲートウェイでマッチせず 401 になるため除去する。
  api_id = replace(azurerm_api_management_api.openai.id, "/;rev=.*/", "")
  state  = "active"
}
