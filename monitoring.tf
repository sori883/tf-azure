# トークン集計クエリのクエリパック（Log Analytics / App Insights の「クエリハブ」に表示される）。
resource "azurerm_log_analytics_query_pack" "token_usage" {
  name                = "${var.name_prefix}-token-queries"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  tags                = var.tags
}

# name は UUID 形式が必須（固定値にして再作成を防ぐ）。
resource "azurerm_log_analytics_query_pack_query" "tokens_by_model" {
  name          = "a1f4e8b2-9c3d-4e6f-8a1b-5d7c9e2f4a60"
  query_pack_id = azurerm_log_analytics_query_pack.token_usage.id
  display_name  = "OpenAI: モデル別トークン集計（Prompt / Completion / Total）"
  description   = "llm-emit-token-metric が記録したトークン数をモデル別にピボット集計する。期間は Logs 画面の時間範囲に従う。"
  categories    = ["applications", "monitor"]
  resource_types = [
    "microsoft.insights/components",
  ]

  body = <<-KQL
    customMetrics
    | where name in ("Total Tokens", "Prompt Tokens", "Completion Tokens")
    | extend Model = coalesce(tostring(customDimensions["Model"]), "unknown")
    | summarize Tokens = sum(valueSum) by Model, name
    | evaluate pivot(name, sum(Tokens))
    | order by ["Total Tokens"] desc
  KQL
}

resource "azurerm_log_analytics_query_pack_query" "tokens_by_model_timeseries" {
  name          = "b2e5f9c3-0d4e-4f70-9b2c-6e8d0f3a5b71"
  query_pack_id = azurerm_log_analytics_query_pack.token_usage.id
  display_name  = "OpenAI: モデル別トークン推移（1時間ビン）"
  description   = "Total Tokens をモデル別・1時間単位で集計する。render timechart 付き。"
  categories    = ["applications", "monitor"]
  resource_types = [
    "microsoft.insights/components",
  ]

  body = <<-KQL
    customMetrics
    | where name == "Total Tokens"
    | extend Model = coalesce(tostring(customDimensions["Model"]), "unknown")
    | summarize Tokens = sum(valueSum) by Model, bin(timestamp, 1h)
    | render timechart
  KQL
}

resource "azurerm_log_analytics_query_pack_query" "tokens_by_model_subscription" {
  name          = "c3f60ad4-1e5f-4081-ac3d-7f9e1a4b6c82"
  query_pack_id = azurerm_log_analytics_query_pack.token_usage.id
  display_name  = "OpenAI: モデル × APIMサブスクリプション別トークン"
  description   = "利用者（APIM サブスクリプション）単位でモデル別のトークン消費を集計する。"
  categories    = ["applications", "monitor"]
  resource_types = [
    "microsoft.insights/components",
  ]

  body = <<-KQL
    customMetrics
    | where name == "Total Tokens"
    | extend Model = coalesce(tostring(customDimensions["Model"]), "unknown")
    | extend Subscription = coalesce(tostring(customDimensions["Subscription ID"]), "unknown")
    | summarize Tokens = sum(valueSum) by Model, Subscription
    | order by Tokens desc
  KQL
}

# モデル別トークン使用量の集計 Workbook。
# データソースは Log Analytics の customMetrics テーブル（llm-emit-token-metric が送信）。
# ログベースの集計のため「次元付きカスタムメトリクス」のポータル設定は不要。
resource "azurerm_application_insights_workbook" "token_usage" {
  # name は UUID 形式が必須（固定値にして再作成を防ぐ）。
  name                = "d3b1c9a0-7f42-4e5b-9c8d-2a6e1f0b4c7d"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  display_name        = "OpenAI Token Usage (by model)"
  source_id           = lower(azurerm_application_insights.main.id)
  tags                = var.tags

  data_json = jsonencode({
    version = "Notebook/1.0"
    items = [
      {
        type = 1
        name = "header"
        content = {
          json = "## Azure OpenAI トークン使用量（モデル別）\n\nAPIM の `llm-emit-token-metric` ポリシーが記録したトークン数を、リクエストボディの `model`（= デプロイ名）ごとに集計します。"
        }
      },
      {
        type = 9
        name = "parameters"
        content = {
          version = "KqlParameterItem/1.0"
          style   = "pills"
          parameters = [
            {
              id         = "5e0c9b1f-3a7d-4f26-8b41-c9d2e6a05b38"
              version    = "KqlParameterItem/1.0"
              name       = "TimeRange"
              label      = "期間"
              type       = 4
              isRequired = true
              value      = { durationMs = 86400000 }
              typeSettings = {
                selectableValues = [
                  { durationMs = 3600000 },    # 1時間
                  { durationMs = 86400000 },   # 24時間
                  { durationMs = 604800000 },  # 7日
                  { durationMs = 2592000000 }, # 30日
                ]
              }
            }
          ]
          queryType    = 0
          resourceType = "microsoft.insights/components"
        }
      },
      {
        type = 3
        name = "tokens-by-model-table"
        content = {
          version                  = "KqlItem/1.0"
          title                    = "モデル別トークン集計（Prompt / Completion / Total）"
          query                    = <<-KQL
            customMetrics
            | where name in ("Total Tokens", "Prompt Tokens", "Completion Tokens")
            | extend Model = coalesce(tostring(customDimensions["Model"]), "unknown")
            | summarize Tokens = sum(valueSum) by Model, name
            | evaluate pivot(name, sum(Tokens))
            | order by ["Total Tokens"] desc
          KQL
          size                     = 0
          timeContextFromParameter = "TimeRange"
          queryType                = 0
          resourceType             = "microsoft.insights/components"
          visualization            = "table"
        }
      },
      {
        type = 3
        name = "tokens-by-model-timechart"
        content = {
          version                  = "KqlItem/1.0"
          title                    = "モデル別トークン推移（Total Tokens）"
          query                    = <<-KQL
            customMetrics
            | where name == "Total Tokens"
            | extend Model = coalesce(tostring(customDimensions["Model"]), "unknown")
            | summarize Tokens = sum(valueSum) by Model, bin(timestamp, {TimeRange:grain})
          KQL
          size                     = 0
          timeContextFromParameter = "TimeRange"
          queryType                = 0
          resourceType             = "microsoft.insights/components"
          visualization            = "timechart"
        }
      },
      {
        type = 3
        name = "tokens-by-model-subscription"
        content = {
          version                  = "KqlItem/1.0"
          title                    = "モデル × APIM サブスクリプション別（Total Tokens）"
          query                    = <<-KQL
            customMetrics
            | where name == "Total Tokens"
            | extend Model = coalesce(tostring(customDimensions["Model"]), "unknown")
            | extend Subscription = coalesce(tostring(customDimensions["Subscription ID"]), "unknown")
            | summarize Tokens = sum(valueSum) by Model, Subscription
            | order by Tokens desc
          KQL
          size                     = 0
          timeContextFromParameter = "TimeRange"
          queryType                = 0
          resourceType             = "microsoft.insights/components"
          visualization            = "table"
        }
      },
    ]
    fallbackResourceIds = [lower(azurerm_application_insights.main.id)]
  })
}
