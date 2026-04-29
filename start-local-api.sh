#!/bin/bash

# ローカルAPI Gatewayサーバーを起動するスクリプト

set -e

PORT=${1:-3000}

echo "🌐 ローカルAPI Gatewayを起動中..."
echo "   ポート: $PORT"
echo "   テンプレート: template.yaml"
echo ""
echo "利用可能なエンドポイント:"
echo "   POST http://localhost:$PORT/cors-for-smalruby"
echo "   GET  http://localhost:$PORT/cors-proxy?url=<URL>"
echo "   GET  http://localhost:$PORT/mesh-zone"
echo "   GET  http://localhost:$PORT/projects/{projectId}"
echo "   GET  http://localhost:$PORT/translate?language=<LANG>&text=<TEXT>"
echo ""
echo "停止するには Ctrl+C を押してください"
echo ""

# 環境変数の設定
export SAM_CLI_TELEMETRY=0

# ローカルAPI Gatewayを起動
sam local start-api --port "$PORT" --parameter-overrides "ParameterKey=Environment,ParameterValue=local"