# tf-azure

Azure OpenAI（gpt-5.4-pro）を **APIM 経由でのみ** アクセス可能な形でデプロイする Terraform 構成。

## アーキテクチャ

```
インターネット ──(Ocp-Apim-Subscription-Key)──▶ APIM (public gateway / Developer)
                                                  │  External VNet injection
                                                  │  アウトバウンドは VNet 経由
                                                  ▼
                                                 VNet
                                                  │  (Managed Identity)
                                                  ▼
                              Private Endpoint ──▶ Azure OpenAI（public 無効）
                              privatelink.openai.azure.com
```

- **APIM は VNet に載る（public gateway 維持）**: Developer SKU の External VNet injection。ゲートウェイは public のままインターネットから利用でき、アウトバウンド通信のみ VNet 経由になる。
- **AOAI は閉域**: `public_network_access_enabled = false` とし、Private Endpoint 経由でのみアクセス可能。インターネットからの直接アクセスは不可。
- **キーレス認証**: APIM のマネージド ID に `Cognitive Services OpenAI User` ロールを付与。API ポリシーの `authentication-managed-identity` でトークンを取得して AOAI を呼ぶため、AOAI の API キーは露出しない。
- **module 分離**: APIM は `modules/apim/`、ネットワークは `modules/network/`。

> SKU は Developer のまま。VNet injection にはコスト増要因がほぼなく、追加は Public IP / Private Endpoint / Private DNS Zone のみ（概算 月$10前後）。

> 注: `gpt-5.4-pro` のモデル名 / バージョン / SKU / リージョン可用性は環境依存です。`terraform.tfvars` の `aoai_model_*` / `aoai_deployment_*` で調整してください。

## 前提ツール

| ツール | バージョン |
| --- | --- |
| Terraform | >= 1.15.8 |
| azurerm provider | ~> 4.80 |
| azapi provider | ~> 2.10 |
| Azure CLI | 認証に使用（未インストールの場合は要導入） |

## 構成

```
.
├── versions.tf   # Terraform / provider のバージョン制約、backend 設定
├── providers.tf  # azurerm / azapi provider 設定
├── variables.tf  # 変数（ネットワーク / AOAI / モデル / APIM）
├── main.tf       # RG・network module・APIM module・AOAI・PE・ロール割当
├── outputs.tf    # 出力値（APIM ゲートウェイ URL、サブスクリプションキー 等）
├── terraform.tfvars.example
└── modules/
    ├── apim/      # API Management（VNet injection / API / ポリシー / サブスクリプション）
    └── network/   # VNet / サブネット / NSG / Public IP / Private DNS Zone
```

state はローカル（`terraform.tfstate`）に保存されます。リモート化する場合は
`versions.tf` の `backend "azurerm"` を参照してください。

## 認証

Azure CLI でログインします（未インストールなら Homebrew 等で導入）。

```sh
brew install azure-cli   # 未インストールの場合
az login
az account set --subscription <SUBSCRIPTION_ID>
```

サブスクリプション ID は次のいずれかで指定します。

- `terraform.tfvars` の `subscription_id`
- 環境変数 `ARM_SUBSCRIPTION_ID`

## 使い方

```sh
# 変数ファイルを用意
cp terraform.tfvars.example terraform.tfvars
# 値を編集

terraform init      # 初期化・provider 取得
terraform fmt       # フォーマット
terraform validate  # 構文チェック
terraform plan      # 変更内容の確認
terraform apply     # 適用
```

> APIM（Developer SKU）のプロビジョニングには **30〜45 分** ほどかかります。

## クライアントからの呼び出し

`apply` 後、出力値を取得します（キーは sensitive なので個別に取得）。

```sh
GATEWAY=$(terraform output -raw apim_gateway_url)
KEY=$(terraform output -raw apim_subscription_key)
DEPLOYMENT=$(terraform output -raw openai_deployment_name)
```

APIM ゲートウェイ経由で Responses API を呼び出します（AOAI へ直接はアクセス不可）。
デプロイ名はボディの `model` で指定します。

```sh
curl -sS "${GATEWAY}/openai/responses" \
  -H "Content-Type: application/json" \
  -H "Ocp-Apim-Subscription-Key: ${KEY}" \
  -d "{\"model\":\"${DEPLOYMENT}\",\"input\":\"Hello\"}"
```

- 認証は APIM のサブスクリプションキー（`Ocp-Apim-Subscription-Key`）のみ。AOAI の API キーは不要（APIM のマネージド ID が代行）。
- 公開している操作は **Responses API（`POST /responses`）のみ**。Chat Completions 等は APIM で公開していないため呼び出せません。
- 別のエンドポイントを使う場合は `modules/apim/main.tf` に operation を追加します。

## トークン使用量の記録

`llm-emit-token-metric` ポリシーにより、リクエストごとのトークン使用量
（Total / Prompt / Completion Tokens）が **Application Insights のカスタムメトリクス**
（名前空間 `AzureOpenAI`、次元: API ID / Operation ID / Subscription ID / **Model**）として記録されます。
Model 次元はリクエストボディの `model`（= デプロイ名）をポリシー式で抽出したものです。
Responses API はこのポリシーの公式サポート対象です。値はレスポンスの `usage` セクションから取得されます。

### モデル別の集計（Workbook）

Terraform が **「OpenAI Token Usage (by model)」Workbook** を作成します
（Application Insights の「ブック」から開けます。ID: `terraform output token_usage_workbook_id`）。

- モデル別トークン集計（Prompt / Completion / Total のピボット表）
- モデル別トークン推移（時系列グラフ）
- モデル × APIM サブスクリプション別の集計
- 期間切替（1時間 / 24時間 / 7日 / 30日）

集計は Log Analytics の `customMetrics` テーブルへの KQL で行うため、
**「次元付きカスタムメトリクス」のポータル設定は不要**です（次元は `customDimensions` に常に保存される）。
アドホックに集計する場合の KQL 例:

```kusto
customMetrics
| where name == "Total Tokens"
| extend Model = tostring(customDimensions["Model"])
| summarize Tokens = sum(valueSum) by Model, bin(timestamp, 1h)
```

注意:

- **ストリーミング**（`"stream": true`）の場合、トークン数は推定値になることがあります。
  正確な値が必要な場合はリクエストで usage を含める設定にしてください。
- ポータルの**メトリック画面**（Azure Monitor メトリクスDB）で次元分割したい場合のみ、
  「次元付きカスタムメトリクス」の有効化（Usage and estimated costs → Custom metrics）が必要です
  （Workbook / KQL には不要）。
- リクエスト単位の詳細ログは API 診断設定（`applicationinsights`、サンプリング 100%）で
  `requests` テーブルにも記録されます。
