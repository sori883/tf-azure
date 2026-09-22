# 実環境の tfvars に保存した版やモデル選択をテストへ持ち込まない。
variables {
  location        = "eastus2"
  model_keys      = null
  model_overrides = {}
}

mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      subscription_id = "00000000-0000-0000-0000-000000000000"
    }
  }

  mock_resource "azurerm_cognitive_account" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-foundry-model-retirement/providers/Microsoft.CognitiveServices/accounts/test-foundry"
    }
  }
}

run "create_private_foundry_without_models" {
  command = apply

  variables {
    model_keys = []
  }

  assert {
    condition = (
      length(azurerm_cognitive_deployment.models) == 0 &&
      azurerm_cognitive_account.foundry.kind == "AIServices" &&
      azurerm_cognitive_account.foundry.location == "eastus2" &&
      !azurerm_cognitive_account.foundry.public_network_access_enabled &&
      !azurerm_cognitive_account.foundry.local_auth_enabled &&
      azurerm_cognitive_account.foundry.network_acls[0].default_action == "Deny" &&
      azurerm_cognitive_account.foundry.network_acls[0].bypass == "None" &&
      length(azurerm_cognitive_account.foundry.network_acls[0].ip_rules) == 0 &&
      azurerm_cognitive_account_project.inspection.cognitive_account_id == output.foundry_resource_id
    )
    error_message = "入力 ID なしで East US 2 に Foundry とプロジェクトを作成し、公開アクセス・キー認証・ネットワーク例外を無効化する必要があります。"
  }
}

run "catalog_versions" {
  command = plan

  assert {
    condition     = length(azurerm_cognitive_deployment.models) == 43
    error_message = "既定ではカタログの43モデルを選択する必要があります。"
  }

  assert {
    condition = alltrue([
      for deployment in azurerm_cognitive_deployment.models :
      deployment.cognitive_account_id == azurerm_cognitive_account.foundry.id
    ])
    error_message = "全モデルが Terraform で作成した Foundry の ID を参照する必要があります。"
  }

  assert {
    condition = (
      azurerm_cognitive_deployment.models["gpt-4o-2024-11-20"].model[0].name == "gpt-4o" &&
      azurerm_cognitive_deployment.models["gpt-4o-2024-11-20"].model[0].version == "2024-11-20"
    )
    error_message = "GPT-4o のモデル名とモデル版を正しく設定する必要があります。"
  }

  assert {
    condition     = azurerm_cognitive_deployment.models["gpt-41"].model[0].version == null
    error_message = "openapi_api_version をモデル版として使用してはいけません。"
  }

  assert {
    condition = (
      azurerm_cognitive_deployment.models["gpt-51-codex-max"].name == "gpt-51-codex-max" &&
      azurerm_cognitive_deployment.models["gpt-51-codex-max"].version_upgrade_option == "NoAutoUpgrade"
    )
    error_message = "deployment フィールドなしで YAML キーをデプロイ名にし、自動更新を無効にする必要があります。"
  }
}

run "selected_model_overrides" {
  command = plan

  variables {
    model_keys = ["gpt-4o-2024-11-20", "gpt-41-mini"]
    model_overrides = {
      "gpt-4o-2024-11-20" = {
        model_version = "2024-08-06"
        sku_name      = "Standard"
        capacity      = 10
      }
      "gpt-41-mini" = {
        capacity = 2
      }
    }
  }

  assert {
    condition = (
      length(azurerm_cognitive_deployment.models) == 2 &&
      azurerm_cognitive_deployment.models["gpt-4o-2024-11-20"].model[0].version == "2024-08-06" &&
      azurerm_cognitive_deployment.models["gpt-4o-2024-11-20"].sku[0].name == "Standard" &&
      azurerm_cognitive_deployment.models["gpt-4o-2024-11-20"].sku[0].capacity == 10
    )
    error_message = "対象モデルの選択とモデル別の上書きが反映される必要があります。"
  }

  assert {
    condition = (
      azurerm_cognitive_deployment.models["gpt-41-mini"].model[0].version == null &&
      azurerm_cognitive_deployment.models["gpt-41-mini"].sku[0].name == "GlobalStandard" &&
      azurerm_cognitive_deployment.models["gpt-41-mini"].sku[0].capacity == 2
    )
    error_message = "容量だけの上書きでも、未指定のモデル版と既定 SKU を保持する必要があります。"
  }
}

run "unknown_model_key" {
  command = plan

  variables {
    model_keys = ["unknown-model"]
  }

  expect_failures = [var.model_keys]
}

run "unknown_override_key" {
  command = plan

  variables {
    model_keys = []
    model_overrides = {
      "unknown-model" = { capacity = 1 }
    }
  }

  expect_failures = [var.model_overrides]
}
