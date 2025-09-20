require "uri"
require "net/http"
require "cgi"
require "json"

ALLOW_ORIGINS = %w(
  https://smalruby.app
  https://smalruby.jp
  http://localhost:8601
)
API_HOST = "https://translate-service.scratch.mit.edu"

def lambda_handler(event:, context:)
  origin = event.dig("headers", "origin").to_s.strip
  headers = {
    "Access-Control-Allow-Origin": ALLOW_ORIGINS.include?(origin) ? origin : ALLOW_ORIGINS.first,
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Allow-Methods": "OPTIONS,GET"
  }

  if event["httpMethod"] == "OPTIONS"
    return {
      statusCode: 200,
      headers:,
      body: JSON.generate(message: "OK"),
    }
  end

  language = event.dig("queryStringParameters", "language").to_s.strip
  text = event.dig("queryStringParameters", "text").to_s

  if language.length == 0
    return {
      statusCode: 400,
      headers:,
      body: {
        code: "Bad Request",
        message: "invalid locale code",
      }.to_json
    }
  end

  query = {
    language:,
    text:,
  }.map { |key, value|
    "#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s)}"
  }.join("&")
  api_uri = URI.join(API_HOST, "/translate?#{query}")
  res = Net::HTTP.get_response(api_uri)
  {
    statusCode: res.code,
    headers:,
    body: res.body.force_encoding("utf-8")
  }
end