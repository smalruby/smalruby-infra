# ローカルテスト環境の使用方法

このドキュメントでは、AWS SAMを使用してLambda関数をローカルでテストする方法について説明します。

## 前提条件

- AWS SAM CLI (インストール済み: `sam --version`)
- Docker (SAM Localが使用)
- Ruby 3.2+ (Lambda関数の実行環境)

**注意**: 現在のローカルテスト環境はRuby 3.2を使用しています。本番環境では3.4を使用しますが、SAM Localの制限により3.2を使用します。

## ディレクトリ構成

```
infra/smalruby-infra/
├── template.yaml              # SAMテンプレート
├── lambda/                    # Lambda関数ソースコード
│   ├── cors-for-smalruby/
│   ├── smalruby-cors-proxy/
│   ├── smalruby-mesh-zone-get/
│   ├── smalruby-scratch-api-proxy-get-project-info/
│   └── smalruby-scratch-api-proxy-translate/
├── events/                    # テスト用イベントファイル
│   ├── cors-for-smalruby.json
│   ├── smalruby-cors-proxy.json
│   ├── smalruby-mesh-zone-get.json
│   ├── smalruby-scratch-api-proxy-get-project-info.json
│   ├── smalruby-scratch-api-proxy-translate.json
│   └── smalruby-scratch-api-proxy-translate-options.json
├── test-local.sh              # 個別Lambda関数テスト
├── test-all-local.sh          # 全Lambda関数テスト
├── start-local-api.sh         # ローカルAPI Gateway起動
└── test-api-endpoints.sh      # API エンドポイントテスト
```

## 使用方法

### 1. 個別Lambda関数のテスト

単一のLambda関数をテストする場合：

```bash
# 特定の関数をテスト
./test-local.sh CorsForSmalruby events/cors-for-smalruby.json

# イベントファイルを省略（デフォルトのイベントファイルを使用）
./test-local.sh SmalrubyCorsProxy

# 利用可能な関数一覧を表示
./test-local.sh
```

### 2. 全Lambda関数のテスト

すべてのLambda関数を一度にテストする場合：

```bash
./test-all-local.sh
```

### 3. ローカルAPI Gatewayサーバーの起動

API Gateway経由でのテストを行う場合：

```bash
# デフォルトポート（3000）で起動
./start-local-api.sh

# カスタムポートで起動
./start-local-api.sh 8080
```

API Gatewayが起動すると、以下のエンドポイントが利用可能になります：

- `POST http://localhost:3000/cors-for-smalruby`
- `GET http://localhost:3000/cors-proxy?url=<URL>`
- `GET http://localhost:3000/mesh-zone`
- `GET http://localhost:3000/projects/{projectId}`
- `GET http://localhost:3000/translate?language=<LANG>&text=<TEXT>`

### 4. API エンドポイントのテスト

起動中のローカルAPI Gatewayに対してHTTPリクエストを送信してテストする場合：

```bash
# デフォルトURL（localhost:3000）でテスト
./test-api-endpoints.sh

# カスタムURLでテスト
./test-api-endpoints.sh http://localhost:8080
```

## テスト例

### curlを使用した手動テスト

```bash
# CORS for Smalruby
curl -X POST http://localhost:3000/cors-for-smalruby \
  -H "Origin: https://smalruby.app"

# CORS Proxy
curl -X GET "http://localhost:3000/cors-proxy?url=https://httpbin.org/get" \
  -H "Origin: https://smalruby.app"

# Mesh Zone Get
curl -X GET http://localhost:3000/mesh-zone

# Scratch API - Project Info
curl -X GET http://localhost:3000/projects/123456789 \
  -H "Origin: https://smalruby.app"

# Scratch API - Translate
curl -X GET "http://localhost:3000/translate?language=ja&text=Hello%20World" \
  -H "Origin: https://smalruby.app"

# OPTIONS request
curl -X OPTIONS http://localhost:3000/translate \
  -H "Origin: https://smalruby.app"
```

## テスト結果の例

### 成功レスポンス例

```json
// CORS for Smalruby
{
  "statusCode": 200,
  "headers": {
    "Access-Control-Allow-Origin": "https://smalruby.app",
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Allow-Methods": "OPTIONS,GET"
  },
  "body": "{\"message\":\"OK\"}"
}

// Mesh Zone Get
{
  "statusCode": 200,
  "headers": {
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "OPTIONS,GET"
  },
  "body": "{\"domain\":\"f7c4453f\"}"
}

// CORS Proxy (外部URL 404エラーの例)
{
  "statusCode": 404,
  "headers": {
    "Access-Control-Allow-Origin": "https://smalruby.app",
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Allow-Methods": "OPTIONS,GET"
  },
  "body": "{\"code\":\"HTTP Error\",\"message\":\"HTTP 404: Not Found\"}",
  "isBase64Encoded": false
}
```

## トラブルシューティング

### よくある問題

1. **Docker が起動していない**
   ```
   Error: Unable to download the image lambda:ruby3.4-x86_64
   ```
   → Docker Desktop を起動してください

2. **ポートが既に使用されている**
   ```
   Error: Port 3000 is in use by another process
   ```
   → 別のポートを指定するか、使用中のプロセスを停止してください

3. **外部API接続エラー**
   ```
   HTTP Error: 404: Not Found
   ```
   → 外部APIへの接続が必要な機能（Scratch API等）は、ネットワーク接続を確認してください

### ログの確認

SAM Localは詳細なログを出力します：

```bash
# デバッグモードで起動
sam local start-api --debug

# ログレベルを指定
sam local invoke CorsForSmalruby --event events/cors-for-smalruby.json --log-file sam-local.log
```

## 開発ワークフロー

1. **Lambda関数の修正** → `lambda/*/lambda_function.rb`
2. **単体テストの実行** → `bundle exec rake test`
3. **ローカルテストの実行** → `./test-local.sh [function-name]`
4. **API統合テストの実行** → `./start-local-api.sh` + `./test-api-endpoints.sh`
5. **コミット** → `git add . && git commit -m "..."`

## 注意点

- 外部API（Scratch API等）への接続が必要な機能は、ネットワーク接続と実際のAPIの可用性に依存します
- Docker イメージのダウンロードに時間がかかる場合があります（初回のみ）
- SAM Local は本番環境とは異なる場合があるため、最終的なテストはAWSにデプロイして行うことを推奨します