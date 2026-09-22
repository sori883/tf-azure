output "foundry_resource_id" {
  description = "新規作成した Foundry 本体のリソース ID。入力は不要。"
  value       = azurerm_cognitive_account.foundry.id
}

output "foundry" {
  description = "Foundry の画面で開くリソースとプロジェクト。"
  value = {
    name                = azurerm_cognitive_account.foundry.name
    resource_group_name = azurerm_resource_group.foundry.name
    location            = azurerm_cognitive_account.foundry.location
    project_name        = azurerm_cognitive_account_project.inspection.name
    project_id          = azurerm_cognitive_account_project.inspection.id
  }
}

output "network_access" {
  description = "Azure から読み取った Foundry リソースの公開アクセス設定。"
  value = {
    public_network_access_enabled = azurerm_cognitive_account.foundry.public_network_access_enabled
    local_auth_enabled            = azurerm_cognitive_account.foundry.local_auth_enabled
    default_action                = azurerm_cognitive_account.foundry.network_acls[0].default_action
    bypass                        = azurerm_cognitive_account.foundry.network_acls[0].bypass
  }
}

output "deployments" {
  description = "Foundry で確認するデプロイ一覧。model_version は Azure から読み取った版。終了日は Foundry の画面で確認する。"
  value = {
    for key, deployment in azurerm_cognitive_deployment.models : key => {
      id                     = deployment.id
      deployment_name        = deployment.name
      model_name             = deployment.model[0].name
      model_version          = deployment.model[0].version
      sku_name               = deployment.sku[0].name
      capacity               = deployment.sku[0].capacity
      version_upgrade_option = deployment.version_upgrade_option
    }
  }
}
