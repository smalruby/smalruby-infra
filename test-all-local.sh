#!/bin/bash

# すべてのLambda関数をローカルでテストするスクリプト

set -e

echo "🧪 全Lambda関数のローカルテストを開始..."
echo "========================================"

# 関数名の配列
FUNCTIONS=(
  "CorsForSmalrubyFunction"
  "SmalrubyCorsProxyFunction"
  "SmalrubyMeshZoneGetFunction"
  "SmalrubyGetProjectInfoFunction"
  "SmalrubyTranslateProxyFunction"
)

# 対応するイベントファイルの配列
EVENT_FILES=(
  "events/cors-for-smalruby.json"
  "events/smalruby-cors-proxy.json"
  "events/smalruby-mesh-zone-get.json"
  "events/smalruby-scratch-api-proxy-get-project-info.json"
  "events/smalruby-scratch-api-proxy-translate.json"
)

TOTAL_TESTS=${#FUNCTIONS[@]}
PASSED_TESTS=0
FAILED_TESTS=0

for i in "${!FUNCTIONS[@]}"; do
  FUNCTION_NAME="${FUNCTIONS[$i]}"
  EVENT_FILE="${EVENT_FILES[$i]}"

  echo ""
  echo "📋 テスト中: $FUNCTION_NAME"
  echo "   イベント: $EVENT_FILE"
  echo "   ----------------------------------------"

  if sam local invoke "$FUNCTION_NAME" --event "$EVENT_FILE" --parameter-overrides "ParameterKey=Environment,ParameterValue=local"; then
    echo "   ✅ $FUNCTION_NAME - PASSED"
    ((PASSED_TESTS++))
  else
    echo "   ❌ $FUNCTION_NAME - FAILED"
    ((FAILED_TESTS++))
  fi
done

echo ""
echo "========================================"
echo "🏁 テスト完了"
echo "   総テスト数: $TOTAL_TESTS"
echo "   成功: $PASSED_TESTS"
echo "   失敗: $FAILED_TESTS"

if [ $FAILED_TESTS -eq 0 ]; then
  echo "   🎉 すべてのテストが成功しました！"
  exit 0
else
  echo "   ⚠️  $FAILED_TESTS 個のテストが失敗しました"
  exit 1
fi