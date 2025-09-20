# frozen_string_literal: true

require "spec_helper"

# Load the specific Lambda function
load File.join(__dir__, "../../lambda/smalruby-scratch-api-proxy-translate/lambda_function.rb")

RSpec.describe "smalruby-scratch-api-proxy-translate lambda function" do
  let(:context) { double("context") }
  let(:valid_origin) { "https://smalruby.app" }

  describe "lambda_handler" do
    context "with OPTIONS request" do
      let(:event) do
        {
          "httpMethod" => "OPTIONS",
          "headers" => {"origin" => valid_origin}
        }
      end

      it "returns 200 with CORS headers" do
        result = SmalrubyScratchApiProxyTranslate.lambda_handler(event: event, context: context)

        expect(result[:statusCode]).to eq(200)
        expect(result[:headers][:"Access-Control-Allow-Origin"]).to eq(valid_origin)
        expect(result[:headers][:"Access-Control-Allow-Methods"]).to eq("OPTIONS,GET")

        body = JSON.parse(result[:body])
        expect(body["message"]).to eq("OK")
      end
    end

    context "with valid translation request" do
      let(:event) do
        {
          "httpMethod" => "GET",
          "headers" => {"origin" => valid_origin},
          "queryStringParameters" => {
            "language" => "ja",
            "text" => "Hello World"
          }
        }
      end

      before do
        stub_request(:get, "https://translate-service.scratch.mit.edu/translate")
          .with(query: {language: "ja", text: "Hello World"})
          .to_return(
            status: 200,
            body: '{"result": "こんにちは世界"}',
            headers: {"Content-Type" => "application/json"}
          )
      end

      it "proxies translation request to Scratch API" do
        result = SmalrubyScratchApiProxyTranslate.lambda_handler(event: event, context: context)

        expect(result[:statusCode]).to eq("200")
        expect(result[:headers][:"Access-Control-Allow-Origin"]).to eq(valid_origin)

        body = JSON.parse(result[:body])
        expect(body["result"]).to eq("こんにちは世界")
      end
    end

    context "with missing language parameter" do
      let(:event) do
        {
          "httpMethod" => "GET",
          "headers" => {"origin" => valid_origin},
          "queryStringParameters" => {
            "text" => "Hello World"
          }
        }
      end

      it "returns 400 bad request" do
        result = SmalrubyScratchApiProxyTranslate.lambda_handler(event: event, context: context)

        expect(result[:statusCode]).to eq(400)

        body = JSON.parse(result[:body])
        expect(body["code"]).to eq("Bad Request")
        expect(body["message"]).to eq("invalid locale code")
      end
    end

    context "with empty language parameter" do
      let(:event) do
        {
          "httpMethod" => "GET",
          "headers" => {"origin" => valid_origin},
          "queryStringParameters" => {
            "language" => "",
            "text" => "Hello World"
          }
        }
      end

      it "returns 400 bad request" do
        result = SmalrubyScratchApiProxyTranslate.lambda_handler(event: event, context: context)

        expect(result[:statusCode]).to eq(400)

        body = JSON.parse(result[:body])
        expect(body["code"]).to eq("Bad Request")
        expect(body["message"]).to eq("invalid locale code")
      end
    end

    context "with invalid origin" do
      let(:event) do
        {
          "httpMethod" => "GET",
          "headers" => {"origin" => "https://evil.com"},
          "queryStringParameters" => {
            "language" => "ja",
            "text" => "Hello World"
          }
        }
      end

      before do
        stub_request(:get, "https://translate-service.scratch.mit.edu/translate")
          .with(query: {language: "ja", text: "Hello World"})
          .to_return(status: 200, body: '{"result": "こんにちは世界"}')
      end

      it "uses default origin in CORS headers" do
        result = SmalrubyScratchApiProxyTranslate.lambda_handler(event: event, context: context)

        expect(result[:headers][:"Access-Control-Allow-Origin"]).to eq("https://smalruby.app")
      end
    end

    context "when Scratch API returns error" do
      let(:event) do
        {
          "httpMethod" => "GET",
          "headers" => {"origin" => valid_origin},
          "queryStringParameters" => {
            "language" => "invalid",
            "text" => "Hello World"
          }
        }
      end

      before do
        stub_request(:get, "https://translate-service.scratch.mit.edu/translate")
          .with(query: {language: "invalid", text: "Hello World"})
          .to_return(
            status: 400,
            body: '{"error": "Invalid language code"}',
            headers: {"Content-Type" => "application/json"}
          )
      end

      it "proxies error response from Scratch API" do
        result = SmalrubyScratchApiProxyTranslate.lambda_handler(event: event, context: context)

        expect(result[:statusCode]).to eq("400")

        body = JSON.parse(result[:body])
        expect(body["error"]).to eq("Invalid language code")
      end
    end
  end
end
