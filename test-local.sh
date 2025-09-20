#!/bin/bash

# ローカルLambda関数テストスクリプト
# Usage: ./test-local.sh [function-name] [event-file]

set -e

FUNCTIONS=(
  "CorsForSmalrubyFunction"
  "SmalrubyCorsProxyFunction"
  "SmalrubyMeshZoneGetFunction"
  "SmalrubyGetProjectInfoFunction"
  "SmalrubyTranslateProxyFunction"
)

# 関数が指定されていない場合、利用可能な関数を表示
if [ $# -eq 0 ]; then
  echo "利用可能なLambda関数:"
  for func in "${FUNCTIONS[@]}"; do
    echo "  - $func"
  done
  echo ""
  echo "使用方法:"
  echo "  ./test-local.sh [function-name] [event-file]"
  echo ""
  echo "例:"
  echo "  ./test-local.sh CorsForSmalruby events/cors-for-smalruby.json"
  echo "  ./test-local.sh SmalrubyCorsProxy events/smalruby-cors-proxy.json"
  exit 1
fi

FUNCTION_NAME=$1
# 関数名とイベントファイルのマッピング
if [ -z "$2" ]; then
  case "$FUNCTION_NAME" in
    "CorsForSmalrubyFunction")
      EVENT_FILE="events/cors-for-smalruby.json"
      ;;
    "SmalrubyCorsProxyFunction")
      EVENT_FILE="events/smalruby-cors-proxy.json"
      ;;
    "SmalrubyMeshZoneGetFunction")
      EVENT_FILE="events/smalruby-mesh-zone-get.json"
      ;;
    "SmalrubyGetProjectInfoFunction")
      EVENT_FILE="events/smalruby-scratch-api-proxy-get-project-info.json"
      ;;
    "SmalrubyTranslateProxyFunction")
      EVENT_FILE="events/smalruby-scratch-api-proxy-translate.json"
      ;;
    *)
      echo "エラー: 不明な関数名 '$FUNCTION_NAME'"
      exit 1
      ;;
  esac
else
  EVENT_FILE="$2"
fi

# イベントファイルの存在確認
if [ ! -f "$EVENT_FILE" ]; then
  echo "エラー: イベントファイル '$EVENT_FILE' が見つかりません"
  echo "利用可能なイベントファイル:"
  ls -1 events/*.json 2>/dev/null || echo "  events/ディレクトリにイベントファイルがありません"
  exit 1
fi

echo "🚀 ローカルLambda関数をテスト中..."
echo "関数名: $FUNCTION_NAME"
echo "イベントファイル: $EVENT_FILE"
echo ""

# SAM local invokeを実行
sam local invoke "$FUNCTION_NAME" --event "$EVENT_FILE" --parameter-overrides "ParameterKey=Environment,ParameterValue=local"