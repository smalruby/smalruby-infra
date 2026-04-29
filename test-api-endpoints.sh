#!/bin/bash

# ローカルAPI Gatewayエンドポイントをテストするスクリプト

set -e

API_BASE_URL=${1:-"http://localhost:3000"}

echo "🧪 ローカルAPI Gatewayエンドポイントをテスト中..."
echo "ベースURL: $API_BASE_URL"
echo ""

# テスト関数
test_endpoint() {
  local name="$1"
  local method="$2"
  local url="$3"
  local expected_status="$4"
  local extra_headers="$5"

  echo "📋 テスト: $name"
  echo "   URL: $method $url"

  local headers="-H 'Origin: https://smalruby.app' -H 'Content-Type: application/json'"
  if [ -n "$extra_headers" ]; then
    headers="$headers $extra_headers"
  fi

  local response
  local status_code

  if [ "$method" = "GET" ]; then
    response=$(eval "curl -s -w '\\n%{http_code}' $headers '$url'")
  elif [ "$method" = "POST" ]; then
    response=$(eval "curl -s -w '\\n%{http_code}' -X POST $headers '$url'")
  elif [ "$method" = "OPTIONS" ]; then
    response=$(eval "curl -s -w '\\n%{http_code}' -X OPTIONS $headers '$url'")
  fi

  status_code=$(echo "$response" | tail -n1)
  body=$(echo "$response" | head -n -1)

  if [ "$status_code" = "$expected_status" ]; then
    echo "   ✅ ステータス: $status_code (期待値: $expected_status)"
    echo "   📄 レスポンス: $body"
  else
    echo "   ❌ ステータス: $status_code (期待値: $expected_status)"
    echo "   📄 レスポンス: $body"
  fi
  echo ""
}

# 各エンドポイントをテスト
echo "開始時刻: $(date)"
echo "========================================"

# 1. CORS for Smalruby
test_endpoint "CORS for Smalruby" "POST" "$API_BASE_URL/cors-for-smalruby" "200"

# 2. CORS Proxy (外部URLは実際には接続できないため、エラーが予想される)
test_endpoint "CORS Proxy" "GET" "$API_BASE_URL/cors-proxy?url=https://httpbin.org/get" "200"

# 3. Mesh Zone Get
test_endpoint "Mesh Zone Get" "GET" "$API_BASE_URL/mesh-zone" "200"

# 4. Scratch API Proxy - Get Project Info (実際のAPIを呼び出すため、ネットワーク接続が必要)
test_endpoint "Scratch API - Get Project Info" "GET" "$API_BASE_URL/projects/123456789" "200"

# 5. Scratch API Proxy - Translate (実際のAPIを呼び出すため、ネットワーク接続が必要)
test_endpoint "Scratch API - Translate" "GET" "$API_BASE_URL/translate?language=ja&text=Hello%20World" "200"

# 6. OPTIONS requests
test_endpoint "Translate OPTIONS" "OPTIONS" "$API_BASE_URL/translate" "200"

echo "========================================"
echo "テスト完了時刻: $(date)"
echo ""
echo "ℹ️  注意:"
echo "   - 外部APIへの接続が必要なエンドポイントは、ネットワーク接続によって結果が変わる場合があります"
echo "   - 実際のScratch APIの応答時間によって、テストに時間がかかる場合があります"