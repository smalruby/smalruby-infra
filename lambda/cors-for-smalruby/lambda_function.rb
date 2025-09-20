require "json"

ALLOW_ORIGINS = %w(
  https://smalruby.app
  https://smalruby.jp
  http://localhost:8601
)

def lambda_handler(event:, context:)
  origin = event.dig("headers", "origin").to_s.strip
  headers = {
    "Access-Control-Allow-Origin": ALLOW_ORIGINS.include?(origin) ? origin : ALLOW_ORIGINS.first,
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Allow-Methods": "OPTIONS,GET"
  }

  {
    statusCode: 200,
    headers:,
    body: JSON.generate(message: "OK"),
  }
end