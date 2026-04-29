# smalruby-infra (DEPRECATED — archived 2026-04-29)

> ⚠️ **このリポジトリは廃止されました**。すべての Lambda 関数 / API Gateway 設定は
> [smalruby/smalruby3-editor](https://github.com/smalruby/smalruby3-editor) リポジトリの
> [`infra/smalruby-api/`](https://github.com/smalruby/smalruby3-editor/tree/develop/infra/smalruby-api)
> に **AWS CDK プロジェクト** として移行されました。

## 移行完了状況

| 旧 (SAM) | 新 (CDK in smalruby3-editor/infra/smalruby-api) |
|----------|--------------------------------------------------|
| `lambda/smalruby-cors-proxy` | `lambda/cors-proxy.ts` (TypeScript / Node.js 20 ARM64) |
| `lambda/smalruby-mesh-zone-get` | `lambda/mesh-zone-get.ts` |
| `lambda/smalruby-scratch-api-proxy-get-project-info` | `lambda/scratch-api-projects.ts` |
| `lambda/smalruby-scratch-api-proxy-translate` | `lambda/scratch-api-translate.ts` |
| `lambda/cors-for-smalruby` | (廃止) HTTP API v2 の built-in CORS で OPTIONS 自動処理 |

CloudFormation スタック `smalruby-infra-prod` は 2026-04-29 に削除済み。
カスタムドメイン `api.smalruby.app` は CDK スタック `SmalrubyApiStack` が
ApiMapping 経由でルーティングしている。

## なぜ移行したか

1. `scratch-api-proxy/projects/{projectId}` のステータスコード透過バグ
   (`Net::HTTP.get` がボディだけ取得し常に 200 を返していた) を修正するため
2. 他の infra プロジェクト (mesh-v2, classroom, rubytee-relay) と同じ
   CDK + TypeScript のスタックに統一するため
3. stg 環境を新設するため (旧実装は prod のみ)

詳細は smalruby3-editor の [Issue #573](https://github.com/smalruby/smalruby3-editor/issues/573)
および [PR #574](https://github.com/smalruby/smalruby3-editor/pull/574) /
[PR #575](https://github.com/smalruby/smalruby3-editor/pull/575) を参照。

## 過去のコミット履歴

旧 SAM 実装のソースコードは git 履歴に残っているため、必要なら
`git log --all` および対象コミットでの参照が可能。
