output "vnet_id" {
  description = "VNet の ID。"
  value       = azurerm_virtual_network.this.id
}

output "apim_subnet_id" {
  description = "APIM VNet injection 用サブネットの ID。"
  value       = azurerm_subnet.apim.id
}

output "pe_subnet_id" {
  description = "Private Endpoint 用サブネットの ID。"
  value       = azurerm_subnet.pe.id
}

output "apim_public_ip_id" {
  description = "APIM injection 用 Standard Public IP の ID。"
  value       = azurerm_public_ip.apim.id
}

output "openai_private_dns_zone_id" {
  description = "Azure OpenAI 用 Private DNS Zone の ID。"
  value       = azurerm_private_dns_zone.openai.id
}
