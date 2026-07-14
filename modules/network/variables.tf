variable "name_prefix" {
  description = "リソース名の接頭辞。"
  type        = string
}

variable "resource_group_name" {
  description = "リソースを作成するリソースグループ名。"
  type        = string
}

variable "location" {
  description = "リージョン。"
  type        = string
}

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

variable "tags" {
  description = "リソースに付与するタグ。"
  type        = map(string)
  default     = {}
}
