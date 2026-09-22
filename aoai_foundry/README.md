# Foundry の画面でモデル終了日を確認するための環境

East US 2 にリソースグループ、Foundry 本体、確認用プロジェクトを新規作成し、`../model_catalog.yaml` から選択したモデルをデプロイします。終了日はデプロイ後に Foundry の画面で確認します。

`foundry_resource_id` は Azure 上の Foundry 本体を識別する ID です。この構成では Terraform が本体を作成してその ID をモデル側へ自動で渡すため、入力は不要です。作成後の ID は同名の output から確認できます。

## モデル廃止日の一覧

カタログの**全43モデルを廃止日の昇順**で記録しています。

- [一覧（Markdown）](model_retirements_all.md)
- [一覧（YAML）](model_retirements_all.yaml)
- [取得日時・画面の表示値（JSON）](model_retirements_all_source.json)

デプロイ済み37件は2026-09-21に Foundry の画面から取得した値、未デプロイ6件は2026-09-22に確認した[Microsoft Learn の廃止予定表](https://learn.microsoft.com/en-us/azure/foundry/openai/concepts/model-retirement-schedule#azure-openai)の値です。各モデルの取得元を明記しています。環境固有のリソース ID や画面 URL は掲載していません。

廃止日は確認時点の記録です。モデル版ごとに異なり、後日変更される可能性があります。

2026-09-21の適用では37モデルと Foundry 本体・プロジェクト・リソースグループの計40リソースの作成に成功しました。適用後の plan は差分なしで、全モデルの版と公開アクセス無効の実設定を確認しました。

設定例は37件すべてのモデル版を固定しています。写真から転記した元のカタログは保持し、Azure から確認した版は設定例に記載しています。確認時点で新規デプロイが拒否された `codex-mini`、`o1`、`o3`、`o3-mini`、`o4-mini` と、利用資格を確認できなかった `o3-pro` は設定例から除外しています。

`gpt-image-2.5-flare` と `gpt-image-2.5-sunburst` の版は、Azure 管理 API と Foundry で確認した `2026-09-08` を採用しています。確認時点のドキュメントに記載された `2026-09-09` とは異なります。

## 設定

現在の `terraform.tfvars` / 設定例の値は次のとおりです。別の環境で初めて使う場合は、`terraform.tfvars.example` を `terraform.tfvars` にコピーし、対象サブスクリプションで提供状況とクォータを確認してください。

| 項目 | 設定値 |
| --- | --- |
| リージョン | `eastus2` |
| リソースグループ名 | `rg-foundry-model-retirement` |
| Foundry 本体の名前 | `foundry-retirement-` にサブスクリプション ID のハッシュ先頭8文字を追加 |
| プロジェクト名 | `model-retirement` |
| モデルデプロイの SKU | `GlobalStandard` |
| モデルデプロイの容量 | `1` |
| 対象モデル | カタログ43件のうち37件 |

- デプロイ名は YAML のキーを使用します。`deployment` フィールドは不要です。
- `model_name` を Azure のモデル名、`model_version` があればモデル版として使用します。
- `openapi_api_version` はモデルの版ではないため、この Terraform では使用しません。
- 写真のモデル名に日付が含まれる GPT-4o は `2024-11-20` を指定し、ほかは未指定なら Azure がデプロイ時の既定版を選択します。
- 現在は `model_keys` に37件を列挙しています。未指定時の既定値 `null` は、廃止移行中のものも含む全43件を選択するため、設定例を使用してください。`model_keys = []` は Foundry 本体とプロジェクトのみを作ります。
- 特定の版や容量が必要なモデルは `model_overrides` で指定します。容量の単位・最小値・対応 SKU はモデルにより異なります。
- 自動更新方針は `NoAutoUpgrade` です。確認中にモデルの版が自動で変わることを避けます。

カタログは写真に記載された名前の転記であり、全43件の新規デプロイ可否は別途確認が必要です。リージョン、モデル版、SKU、クォータ、利用権限によって作成できない場合があります。`plan` 成功は、全モデルの作成成功を保証するものではありません。

## 外部アクセス

Foundry 本体を最初から以下の設定で作成します。

- パブリックネットワークアクセス: 無効
- ネットワーク規則の既定動作: `Deny`
- 信頼済み Azure サービスの例外: `None`
- API キー認証: 無効

IP アドレスの許可規則や Private Endpoint、VNet は作成しません。モデルはこの本体の作成後に追加されます。

Azure Resource Manager 経由のリソース管理は継続できます。Playground 等の推論や、Foundry 画面のうちデータプレーンへ接続する機能は、パブリックネットワークから利用できません。実際の終了日表示はデプロイ後の Foundry 画面で確認します。

## 実行

Terraform `1.15.8` 以上と Azure CLI を使用します。対象サブスクリプションにログインしてから実行します。初回は設定例をコピーし、既存の `terraform.tfvars` がある場合は内容を確認して使用してください。

```sh
cd aoai_foundry
cp -n terraform.tfvars.example terraform.tfvars
export ARM_SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
terraform init
terraform fmt -check
terraform validate
terraform plan -out=tfplan
```

適用する場合は、保存した plan を使用します。

```sh
terraform apply tfplan
terraform output foundry
terraform output network_access
terraform output deployments
```

`Microsoft.CognitiveServices` リソースプロバイダーの登録が前提です。plan 時の自動登録は無効にしています。

認証情報は Azure CLI または環境変数で渡します。`terraform.tfvars`、state、plan、ローカルの実行結果は Git 管理対象外です。既存環境を管理するための state は別途安全に保管してください。

確認用環境を削除する場合は、作成時と同じ state・設定・サブスクリプションを使用します。

```sh
terraform plan -destroy -out=tfplan
terraform apply tfplan
```

## Foundry で確認する項目

1. [Foundry](https://ai.azure.com/) で `terraform output foundry` のリソース・プロジェクトを開きます。
2. モデルのデプロイ一覧から `deployment_name` に対応するデプロイを選びます。
3. 実際のモデル名、モデルバージョン、デプロイ種別と、画面に表示される「Model retirement date」等の終了日を確認します。
4. 比較のため、リージョン、表示された終了日時とタイムゾーン、確認日を一緒に記録します。タイムゾーンがなければ推測で変換せず、終了日が表示されない場合は「表示なし」として記録します。

Terraform の出力には終了日を含めていません。デプロイ済みモデルは Foundry の表示値を優先し、未デプロイモデルをドキュメントから補う場合は取得元を区別して記録します。

## 構成の検証

```sh
terraform test
```

テストはモックプロバイダーを使い、外部から利用できない Foundry の新規作成、作成した ID のモデルへの引き渡し、API バージョンとモデル版の区別、モデル別設定の上書き、不正なカタログキーの拒否を確認します。Azure の実リソースは作成しません。

構成方法の参照: [Foundry の Terraform 構成例](https://learn.microsoft.com/en-us/azure/foundry/how-to/create-resource-terraform)、[AzureRM cognitive_account](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cognitive_account)、[AzureRM cognitive_deployment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cognitive_deployment)。
