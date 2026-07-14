output "name" {
  description = "APIM 名。"
  value       = azurerm_api_management.this.name
}

output "gateway_url" {
  description = "APIM のゲートウェイ URL。"
  value       = azurerm_api_management.this.gateway_url
}

output "outbound_ip_addresses" {
  description = "APIM のアウトバウンド公開 IP（AOAI の network_acls 許可用）。"
  value       = azurerm_api_management.this.public_ip_addresses
}

output "principal_id" {
  description = "APIM のシステム割り当てマネージド ID のプリンシパル ID。"
  value       = azurerm_api_management.this.identity[0].principal_id
}

output "subscription_key" {
  description = "クライアント用の APIM サブスクリプションキー。"
  value       = azurerm_api_management_subscription.openai.primary_key
  sensitive   = true
}
