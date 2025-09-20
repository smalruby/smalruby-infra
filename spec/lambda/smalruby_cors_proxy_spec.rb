# frozen_string_literal: true

require "spec_helper"

# Load the specific Lambda function
load File.join(__dir__, "../../lambda/smalruby-cors-proxy/lambda_function.rb")

RSpec.describe "smalruby-cors-proxy lambda function" do
  let(:context) { double("context") }
  let(:valid_origin) { "https://smalruby.app" }
  let(:invalid_origin) { "https://evil.com" }

  describe "lambda_handler" do
    context "with valid URL parameter" do
      let(:event) do
        {
          "headers" => {"origin" => valid_origin},
          "queryStringParameters" => {"url" => "https://example.com/test.txt"}
        }
      end

      before do
        stub_request(:get, "https://example.com/test.txt")
          .to_return(status: 200, body: "Hello World", headers: {"Content-Type" => "text/plain"})
      end

      it "returns 200 with proxied content" do
        result = lambda_handler(event: event, context: context)

        expect(result[:statusCode]).to eq(200)
        expect(result[:body]).to eq("Hello World")
        expect(result[:headers]["Access-Control-Allow-Origin"]).to eq(valid_origin)
      end

      it "sets correct CORS headers" do
        result = lambda_handler(event: event, context: context)

        expect(result[:headers]["Access-Control-Allow-Origin"]).to eq(valid_origin)
        expect(result[:headers]["Access-Control-Allow-Headers"]).to eq("Content-Type")
        expect(result[:headers]["Access-Control-Allow-Methods"]).to eq("OPTIONS,GET")
      end
    end

    context "with invalid origin" do
      let(:event) do
        {
          "headers" => {"origin" => invalid_origin},
          "queryStringParameters" => {"url" => "https://example.com/test.txt"}
        }
      end

      before do
        stub_request(:get, "https://example.com/test.txt")
          .to_return(status: 200, body: "Hello World")
      end

      it "uses default origin in CORS headers" do
        result = lambda_handler(event: event, context: context)

        expect(result[:headers]["Access-Control-Allow-Origin"]).to eq("https://smalruby.app")
      end
    end

    context "with missing URL parameter" do
      let(:event) do
        {
          "headers" => {"origin" => valid_origin},
          "queryStringParameters" => {}
        }
      end

      it "returns 400 bad request" do
        result = lambda_handler(event: event, context: context)

        expect(result[:statusCode]).to eq(400)
        body = JSON.parse(result[:body])
        expect(body["code"]).to eq("Bad Request")
        expect(body["message"]).to eq("invalid url")
      end
    end

    context "with Google Drive URL" do
      let(:google_drive_url) { "https://drive.google.com/file/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms/view" }
      let(:event) do
        {
          "headers" => {"origin" => valid_origin},
          "queryStringParameters" => {"url" => google_drive_url}
        }
      end

      before do
        stub_request(:get, "https://drive.google.com/uc?export=download&id=1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms")
          .to_return(status: 200, body: "Google Drive Content")
      end

      it "converts Google Drive URL and fetches content" do
        result = lambda_handler(event: event, context: context)

        expect(result[:statusCode]).to eq(200)
        expect(result[:body]).to eq("Google Drive Content")
      end
    end

    context "with binary content" do
      let(:event) do
        {
          "headers" => {"origin" => valid_origin},
          "queryStringParameters" => {"url" => "https://example.com/image.png"}
        }
      end

      before do
        stub_request(:get, "https://example.com/image.png")
          .to_return(
            status: 200,
            body: "\x89PNG\r\n\x1a\n",
            headers: {"Content-Type" => "image/png"}
          )
      end

      it "returns base64 encoded binary data" do
        result = lambda_handler(event: event, context: context)

        expect(result[:statusCode]).to eq(200)
        expect(result[:isBase64Encoded]).to be true
        expect(result[:body]).to be_a(String)
      end
    end

    context "when external request fails" do
      let(:event) do
        {
          "headers" => {"origin" => valid_origin},
          "queryStringParameters" => {"url" => "https://nonexistent.example.com/test"}
        }
      end

      before do
        stub_request(:get, "https://nonexistent.example.com/test")
          .to_raise(SocketError.new("getaddrinfo: Name or service not known"))
      end

      it "returns 500 internal server error" do
        result = lambda_handler(event: event, context: context)

        expect(result[:statusCode]).to eq(500)
        body = JSON.parse(result[:body])
        expect(body["code"]).to eq("Internal Server Error")
        expect(body["message"]).to include("getaddrinfo")
      end
    end
  end
end