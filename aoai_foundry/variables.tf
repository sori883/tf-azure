variable "location" {
  description = "リソースグループ、Foundry 本体、プロジェクトを作成するリージョン。"
  type        = string
  default     = "eastus2"
  nullable    = false
}

variable "resource_group_name" {
  description = "新規作成するリソースグループ名。"
  type        = string
  default     = "rg-foundry-model-retirement"
  nullable    = false
}

variable "foundry_name" {
  description = "新規作成する Foundry 本体の名前。null の場合はサブスクリプション ID から一意な接尾辞を生成。"
  type        = string
  default     = null
}

variable "project_name" {
  description = "Foundry の確認用プロジェクト名。"
  type        = string
  default     = "model-retirement"
  nullable    = false
}

variable "model_keys" {
  description = "デプロイする model_catalog.yaml のキー。null は全モデル、空の集合はデプロイなし。"
  type        = set(string)
  default     = null

  validation {
    condition = var.model_keys == null ? true : alltrue([
      for key in var.model_keys : contains(keys(local.model_catalog), key)
    ])
    error_message = "model_keys には model_catalog.yaml に存在するキーを指定してください。"
  }
}

variable "default_sku_name" {
  description = "モデルデプロイの既定 SKU。モデル別の変更は model_overrides で指定。"
  type        = string
  default     = "GlobalStandard"
  nullable    = false
}

variable "default_capacity" {
  description = "モデルデプロイの既定容量。単位と許容値はモデル・SKU により異なる。"
  type        = number
  default     = 1
  nullable    = false

  validation {
    condition     = var.default_capacity >= 1 && floor(var.default_capacity) == var.default_capacity
    error_message = "default_capacity は 1 以上の整数にしてください。"
  }
}

variable "model_overrides" {
  description = "YAML のキーごとにモデル版・SKU・容量を上書きする設定。"
  type = map(object({
    model_version = optional(string)
    sku_name      = optional(string)
    capacity      = optional(number)
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for key in keys(var.model_overrides) : contains(keys(local.model_catalog), key)
    ])
    error_message = "model_overrides のキーは model_catalog.yaml に存在する必要があります。"
  }

  validation {
    condition = alltrue([
      for config in values(var.model_overrides) :
      config.capacity == null ? true : config.capacity >= 1 && floor(config.capacity) == config.capacity
    ])
    error_message = "model_overrides の capacity は 1 以上の整数にしてください。"
  }
}

variable "version_upgrade_option" {
  description = "モデル版の自動更新方針。終了日の確認対象を保つため、既定では自動更新を無効化。"
  type        = string
  default     = "NoAutoUpgrade"
  nullable    = false

  validation {
    condition = contains([
      "NoAutoUpgrade", "OnceCurrentVersionExpired", "OnceNewDefaultVersionAvailable"
    ], var.version_upgrade_option)
    error_message = "有効なモデル版の自動更新方針を指定してください。"
  }
}
