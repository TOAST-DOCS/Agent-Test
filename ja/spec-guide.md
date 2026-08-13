<!-- machine_translated: true -->

<!-- pre-align:aligned sig=178a08dfcc40 -->

<a id="compute-instance-spec-guide"></a>
## Compute > Instance > リソース仕様ガイド { #compute-instance-spec-guide }

インスタンスAPIレスポンス本文のリソースフィールド仕様を整理したドキュメントです。各フィールドのパス、タイプ、Not Null有無、説明を表で提供します。

<a id="resource-fields"></a>
### リソースフィールド { #resource-fields }

| パス | タイプ | Not Null | 説明 |
| --- | --- | --- | --- |
| resource.id | String | O | リソースIDです。 |
| resource.name | String | O | リソース名です。コンソールで変更できます。名前はプロジェクト内で一意である必要があります。 |
| resource.status | Enum | O | リソースの状態です。<br>[ACTIVE(使用中), PAUSED(一時停止), DELETED(削除済み)] |
| resource.quota | Object | X | リソース割り当て量の情報です。 |
| resource.quota.limit | Integer | X | 最大割り当て量です。デフォルト値は100です。 |
| resource.quota.used | Integer | X | 現在の使用量です。 |
| resource.labels | Array | X | リソースに付与されたラベルのリストです。 |

<a id="spec-change-policy"></a>
### 仕様変更ポリシー { #spec-change-policy }

フィールドの追加は下位互換と見なされ、予告なく反映されることがあります。フィールドの削除またはタイプ変更は、少なくとも30日前にお知らせで案内されます。
