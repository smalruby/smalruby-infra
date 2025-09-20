require "json"
require "zlib"

module SmalrubyMeshZoneGet
  def self.lambda_handler(event:, context:)
    secret_key = "uXM1VAA6MO39yJ+djz4kbpVGy3Rg1V3Z"
    source_ip = event.dig("requestContext", "identity", "sourceIp") || "none"
    domain = Zlib.crc32(secret_key + source_ip).to_s(16)

    {
      statusCode: 200,
      headers: {
        "Access-Control-Allow-Headers": "Content-Type",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "OPTIONS,GET"
      },
      body: JSON.generate(domain: domain)
    }
  end
end

# AWS Lambda entry point
unless ENV["CI"] == "true"
  def lambda_handler(event:, context:)
    SmalrubyMeshZoneGet.lambda_handler(event: event, context: context)
  end
end
