require "uri"
require "net/http"

module SmalrubyScratchApiProxyGetProjectInfo
  ALLOW_ORIGINS = %w[
    https://smalruby.app
    https://smalruby.jp
    http://localhost:8601
  ]

  API_HOST = "https://api.scratch.mit.edu"

  def self.lambda_handler(event:, context:)
    origin = event.dig("headers", "origin").to_s.strip
    headers = {
      "Access-Control-Allow-Origin": ALLOW_ORIGINS.include?(origin) ? origin : ALLOW_ORIGINS.first,
      "Access-Control-Allow-Headers": "Content-Type",
      "Access-Control-Allow-Methods": "OPTIONS,GET"
    }

    project_id = event.dig("pathParameters", "projectId")
    api_uri = URI.join(API_HOST, "/projects/#{project_id}")
    res = Net::HTTP.get(api_uri)
    {
      statusCode: 200,
      headers:,
      body: res.dup.force_encoding("utf-8")
    }
  end
end

# AWS Lambda entry point
def lambda_handler(event:, context:)
  SmalrubyScratchApiProxyGetProjectInfo.lambda_handler(event: event, context: context)
end
