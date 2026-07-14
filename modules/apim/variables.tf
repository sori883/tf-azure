variable "name" {
  description = "APIM インスタンス名（グローバルに一意）。"
  type        = string
}

variable "resource_group_name" {
  description = "APIM を作成するリソースグループ名。"
  type        = string
}

variable "location" {
  description = "リージョン。"
  type        = string
}

variable "sku_name" {
  description = "APIM の SKU（例: Developer_1）。"
  type        = string
  default     = "Developer_1"
}

variable "publisher_name" {
  description = "APIM の発行者名。"
  type        = string
}

variable "publisher_email" {
  description = "APIM の発行者メールアドレス。"
  type        = string
}

variable "aoai_endpoint" {
  description = "バックエンドとなる Azure OpenAI のエンドポイント（例: https://xxx.openai.azure.com）。"
  type        = string
}

variable "subnet_id" {
  description = "VNet injection に使う APIM 用サブネット（Microsoft.ApiManagement/service に委任済み）の ID。"
  type        = string
}

variable "public_ip_address_id" {
  description = "VNet injection に必須の Standard Public IP の ID。"
  type        = string
}

variable "application_insights_id" {
  description = "トークン使用量メトリクスの送信先 Application Insights のリソース ID。"
  type        = string
}

variable "application_insights_instrumentation_key" {
  description = "Application Insights のインストルメンテーションキー。"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "リソースに付与するタグ。"
  type        = map(string)
  default     = {}
}
