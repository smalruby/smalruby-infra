require 'json'
require 'zlib'

def lambda_handler(event:, context:)
    secret_key = "uXM1VAA6MO39yJ+djz4kbpVGy3Rg1V3Z"
    source_ip = event.dig("requestContext", "identity", "sourceIp") || "none"
    domain = Zlib.crc32(secret_key + source_ip).to_s(16)

    {
        statusCode: 200,
        headers: {
            "Access-Control-Allow-Headers": "Content-Type",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "OPTIONS,GET",
        },
        body: JSON.generate(domain: domain),
    }
end