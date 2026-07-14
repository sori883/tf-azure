output "openai_endpoint" {
  description = "Azure OpenAI のデータプレーンエンドポイント（public 無効。アクセスは Private Endpoint 経由のみ）。"
  value       = azurerm_cognitive_account.openai.endpoint
}

output "openai_private_endpoint_id" {
  description = "AOAI の Private Endpoint の ID。"
  value       = azurerm_private_endpoint.openai.id
}

output "openai_deployment_name" {
  description = "モデルデプロイ名（API 呼び出し時の deployment-id）。"
  value       = azurerm_cognitive_deployment.gpt.name
}

output "apim_gateway_url" {
  description = "APIM のゲートウェイ URL。クライアントはここ経由でアクセスする。"
  value       = module.apim.gateway_url
}

output "apim_name" {
  description = "APIM 名。"
  value       = module.apim.name
}

output "application_insights_name" {
  description = "トークン使用量メトリクスが記録される Application Insights 名。"
  value       = azurerm_application_insights.main.name
}

output "token_usage_workbook_id" {
  description = "モデル別トークン集計 Workbook のリソース ID。"
  value       = azurerm_application_insights_workbook.token_usage.id
}

output "apim_subscription_key" {
  description = "APIM サブスクリプションキー（クライアントが Ocp-Apim-Subscription-Key に設定）。"
  value       = module.apim.subscription_key
  sensitive   = true
}
