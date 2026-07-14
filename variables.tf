variable "subscription_id" {
  description = "デプロイ先の Azure サブスクリプション ID。環境変数 ARM_SUBSCRIPTION_ID でも指定可能。"
  type        = string
  default     = null
}

variable "location" {
  description = "リソースを作成する Azure リージョン。"
  type        = string
  default     = "japaneast"
}

variable "environment" {
  description = "環境名（dev / stg / prod など）。リソース名やタグの接頭辞に利用します。"
  type        = string
  default     = "dev"
}

variable "name_prefix" {
  description = <<-EOT
    リソース名の接頭辞。Azure OpenAI アカウント名（= custom subdomain）と
    APIM 名はグローバルに一意である必要があるため、他と衝突しない値を設定すること。
  EOT
  type        = string
}

variable "tags" {
  description = "全リソースに共通で付与するタグ。"
  type        = map(string)
  default = {
    managed_by = "terraform"
  }
}

# ---------------------------------------------------------------------------
# ネットワーク
# ---------------------------------------------------------------------------

variable "vnet_address_space" {
  description = "VNet のアドレス空間。"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "apim_subnet_prefix" {
  description = "APIM（VNet injection）用サブネットの CIDR。"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "pe_subnet_prefix" {
  description = "Private Endpoint 用サブネットの CIDR。"
  type        = list(string)
  default     = ["10.0.2.0/24"]
}

# ---------------------------------------------------------------------------
# Azure OpenAI
# ---------------------------------------------------------------------------

variable "aoai_sku_name" {
  description = "Azure OpenAI（Cognitive Services）アカウントの SKU。"
  type        = string
  default     = "S0"
}

variable "aoai_deployment_name" {
  description = "モデルデプロイ名。API 呼び出し時の deployment-id として使用する。"
  type        = string
  default     = "gpt-5.4-pro"
}

variable "aoai_model_name" {
  description = "デプロイするモデル名。"
  type        = string
  default     = "gpt-5.4-pro"
}

variable "aoai_model_version" {
  description = <<-EOT
    モデルのバージョン。null の場合はそのリージョン/モデルの既定バージョンが使われる。
    gpt-5.4-pro が明示バージョン必須の場合は、対象リージョンで利用可能な値を設定すること。
  EOT
  type        = string
  default     = null
}

variable "aoai_deployment_sku_name" {
  description = "モデルデプロイの SKU 名（GlobalStandard / Standard / DataZoneStandard など）。"
  type        = string
  default     = "GlobalStandard"
}

variable "aoai_deployment_capacity" {
  description = "モデルデプロイのキャパシティ。多くの SKU では 1000 tokens/min 単位。"
  type        = number
  default     = 1
}

# ---------------------------------------------------------------------------
# API Management
# ---------------------------------------------------------------------------

variable "apim_sku_name" {
  description = "APIM の SKU（例: Developer_1, StandardV2_1, Premium_1）。"
  type        = string
  default     = "Developer_1"
}

variable "apim_publisher_name" {
  description = "APIM の発行者名。"
  type        = string
  default     = "tf-azure"
}

variable "apim_publisher_email" {
  description = "APIM の発行者メールアドレス。"
  type        = string
}
