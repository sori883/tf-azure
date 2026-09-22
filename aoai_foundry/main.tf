locals {
  model_catalog = yamldecode(file("${path.module}/../model_catalog.yaml")).models

  selected_models = {
    for key, model in local.model_catalog : key => model
    if var.model_keys == null ? true : contains(var.model_keys, key)
  }

  deployments = {
    for key, model in local.selected_models : key => {
      model_name = model.model_name
      # API バージョンは使用しない。未指定のモデル版は Azure の既定版になる。
      model_version = try(coalesce(
        try(var.model_overrides[key].model_version, null),
        try(model.model_version, null)
      ), null)
      sku_name = coalesce(try(var.model_overrides[key].sku_name, null), var.default_sku_name)
      capacity = coalesce(try(var.model_overrides[key].capacity, null), var.default_capacity)
    }
  }
}

resource "azurerm_cognitive_deployment" "models" {
  for_each = local.deployments

  # 同じ Foundry 本体に対するプロジェクト作成との競合を避ける。
  depends_on = [azurerm_cognitive_account_project.inspection]

  # YAML のキーをそのままデプロイ名にする。
  name                   = each.key
  cognitive_account_id   = azurerm_cognitive_account.foundry.id
  version_upgrade_option = var.version_upgrade_option

  model {
    format  = "OpenAI"
    name    = each.value.model_name
    version = each.value.model_version
  }

  sku {
    name     = each.value.sku_name
    capacity = each.value.capacity
  }
}
