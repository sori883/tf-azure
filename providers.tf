provider "azurerm" {
  # azurerm 4.x では features ブロックが必須です。
  features {}

  # サブスクリプション ID は変数、または環境変数 ARM_SUBSCRIPTION_ID で指定します。
  subscription_id = var.subscription_id
}

provider "azapi" {
  # azurerm と同じ認証情報を利用します。
  # サブスクリプション ID は環境変数 ARM_SUBSCRIPTION_ID でも指定可能です。
  subscription_id = var.subscription_id
}
