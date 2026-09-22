# 全43モデルの廃止日一覧

作成日時: 2026-09-22T16:40:16+09:00

**モデル廃止日の昇順**です。同じ日はモデル名・モデル版の昇順です。`model_catalog.yaml` の43件すべてを含み、重複・未記入はありません。

- **Foundry（37件）**: 2026-09-21に East US 2 のデプロイ詳細画面から取得した値を使用。取得日時と画面の表示値は下記 JSON に記録しています。
- **公式資料（6件）**: 未デプロイの codex-mini / o1 / o3 / o3-mini / o3-pro / o4-mini を、2026-09-22に[Microsoft Learn の廃止予定表](https://learn.microsoft.com/en-us/azure/foundry/openai/concepts/model-retirement-schedule#azure-openai)で確認。

廃止日は対象バージョンのベースモデルの終了日です。API バージョンやファインチューニング版の終了日ではありません。Foundry とドキュメントで差がある場合、デプロイ済みモデルは Foundry の値を優先しています。時刻を除いた日付で並べ、タイムゾーンの変換は行っていません。

環境固有の ID を含む Foundry の画面 URL は省略しています。

[YAML](model_retirements_all.yaml) / [取得元・取得日時・表示値](model_retirements_all_source.json)

| モデル廃止日 | モデル名 | モデルバージョン | 取得元 |
| --- | --- | --- | --- |
| 2026-10-23 | `gpt-image-1` | `2025-04-15` | Foundry |
| 2026-11-15 | `codex-mini` | `2025-05-16` | [公式資料](https://learn.microsoft.com/en-us/azure/foundry/openai/concepts/model-retirement-schedule#azure-openai) |
| 2026-11-19 | `o1` | `2024-12-17` | [公式資料](https://learn.microsoft.com/en-us/azure/foundry/openai/concepts/model-retirement-schedule#azure-openai) |
| 2026-11-19 | `o3` | `2025-04-16` | [公式資料](https://learn.microsoft.com/en-us/azure/foundry/openai/concepts/model-retirement-schedule#azure-openai) |
| 2026-11-19 | `o3-mini` | `2025-01-31` | [公式資料](https://learn.microsoft.com/en-us/azure/foundry/openai/concepts/model-retirement-schedule#azure-openai) |
| 2026-11-19 | `o3-pro` | `2025-06-10` | [公式資料](https://learn.microsoft.com/en-us/azure/foundry/openai/concepts/model-retirement-schedule#azure-openai) |
| 2026-11-19 | `o4-mini` | `2025-04-16` | [公式資料](https://learn.microsoft.com/en-us/azure/foundry/openai/concepts/model-retirement-schedule#azure-openai) |
| 2026-12-02 | `gpt-chat-latest` | `2026-08-06` | Foundry |
| 2026-12-16 | `gpt-image-1.5` | `2025-12-16` | Foundry |
| 2026-12-31 | `gpt-4o-transcribe` | `2025-03-20` | Foundry |
| 2027-02-09 | `gpt-5` | `2025-08-07` | Foundry |
| 2027-02-09 | `gpt-5-mini` | `2025-08-07` | Foundry |
| 2027-02-09 | `gpt-5-nano` | `2025-08-07` | Foundry |
| 2027-04-07 | `gpt-5-pro` | `2025-10-06` | Foundry |
| 2027-04-14 | `gpt-4.1` | `2025-04-14` | Foundry |
| 2027-04-14 | `gpt-4.1-mini` | `2025-04-14` | Foundry |
| 2027-04-14 | `gpt-4.1-nano` | `2025-04-14` | Foundry |
| 2027-04-14 | `gpt-4o` | `2024-11-20` | Foundry |
| 2027-04-15 | `gpt-4o-transcribe-diarize` | `2025-10-15` | Foundry |
| 2027-05-15 | `gpt-5.1` | `2025-11-13` | Foundry |
| 2027-05-15 | `gpt-5.1-codex` | `2025-11-13` | Foundry |
| 2027-05-15 | `gpt-5.1-codex-mini` | `2025-11-13` | Foundry |
| 2027-05-18 | `gpt-5.1-codex-max` | `2025-12-04` | Foundry |
| 2027-06-08 | `gpt-5.2` | `2025-12-11` | Foundry |
| 2027-06-15 | `gpt-4o-mini-transcribe` | `2025-12-15` | Foundry |
| 2027-06-15 | `gpt-4o-mini-tts` | `2025-12-15` | Foundry |
| 2027-07-13 | `gpt-5.2-codex` | `2026-01-14` | Foundry |
| 2027-08-24 | `gpt-5.3-codex` | `2026-02-24` | Foundry |
| 2027-09-02 | `gpt-5.4` | `2026-03-05` | Foundry |
| 2027-09-07 | `gpt-5.4-pro` | `2026-03-05` | Foundry |
| 2027-09-08 | `gpt-image-2.5-flare` | `2026-09-08` | Foundry |
| 2027-09-08 | `gpt-image-2.5-sunburst` | `2026-09-08` | Foundry |
| 2027-09-21 | `gpt-5.4-mini` | `2026-03-17` | Foundry |
| 2027-09-21 | `gpt-5.4-nano` | `2026-03-17` | Foundry |
| 2027-10-21 | `gpt-image-2` | `2026-04-21` | Foundry |
| 2028-01-11 | `gpt-5.6-luna` | `2026-07-09` | Foundry |
| 2028-01-11 | `gpt-5.6-sol` | `2026-07-09` | Foundry |
| 2028-01-11 | `gpt-5.6-terra` | `2026-07-09` | Foundry |
| 2028-01-11 | `gpt-6-astra` | `2026-09-03` | Foundry |
| 2028-02-01 | `gpt-transcribe` | `2026-07-28` | Foundry |
| 2028-02-09 | `text-embedding-3-large` | `1` | Foundry |
| 2028-02-09 | `text-embedding-3-small` | `1` | Foundry |
| 2028-02-09 | `text-embedding-ada-002` | `2` | Foundry |
