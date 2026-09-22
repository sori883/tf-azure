provider "azurerm" {
  features {}

  # plan 時に無関係なリソースプロバイダーを自動登録しない。
  resource_provider_registrations = "none"

  # サブスクリプション ID は環境変数 ARM_SUBSCRIPTION_ID で指定します。
}
