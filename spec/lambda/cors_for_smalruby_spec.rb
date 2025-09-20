# frozen_string_literal: true

require "spec_helper"

# Load the specific Lambda function
load File.join(__dir__, "../../lambda/cors-for-smalruby/lambda_function.rb")

RSpec.describe "cors-for-smalruby lambda function" do
  let(:context) { double("context") }

  describe "lambda_handler" do
    context "with valid origin" do
      let(:event) do
        {
          "headers" => {"origin" => "https://smalruby.app"}
        }
      end

      it "returns 200 with correct CORS headers" do
        result = lambda_handler(event: event, context: context)

        expect(result[:statusCode]).to eq(200)
        expect(result[:headers]["Access-Control-Allow-Origin"]).to eq("https://smalruby.app")
        expect(result[:headers]["Access-Control-Allow-Headers"]).to eq("Content-Type")
        expect(result[:headers]["Access-Control-Allow-Methods"]).to eq("OPTIONS,GET")

        body = JSON.parse(result[:body])
        expect(body["message"]).to eq("OK")
      end
    end

    context "with smalruby.jp origin" do
      let(:event) do
        {
          "headers" => {"origin" => "https://smalruby.jp"}
        }
      end

      it "returns 200 with smalruby.jp origin" do
        result = lambda_handler(event: event, context: context)

        expect(result[:statusCode]).to eq(200)
        expect(result[:headers]["Access-Control-Allow-Origin"]).to eq("https://smalruby.jp")
      end
    end

    context "with localhost origin" do
      let(:event) do
        {
          "headers" => {"origin" => "http://localhost:8601"}
        }
      end

      it "returns 200 with localhost origin" do
        result = lambda_handler(event: event, context: context)

        expect(result[:statusCode]).to eq(200)
        expect(result[:headers]["Access-Control-Allow-Origin"]).to eq("http://localhost:8601")
      end
    end

    context "with invalid origin" do
      let(:event) do
        {
          "headers" => {"origin" => "https://evil.com"}
        }
      end

      it "returns 200 with default origin" do
        result = lambda_handler(event: event, context: context)

        expect(result[:statusCode]).to eq(200)
        expect(result[:headers]["Access-Control-Allow-Origin"]).to eq("https://smalruby.app")
      end
    end

    context "with missing origin header" do
      let(:event) do
        {
          "headers" => {}
        }
      end

      it "returns 200 with default origin" do
        result = lambda_handler(event: event, context: context)

        expect(result[:statusCode]).to eq(200)
        expect(result[:headers]["Access-Control-Allow-Origin"]).to eq("https://smalruby.app")
      end
    end

    context "with empty headers" do
      let(:event) { {} }

      it "returns 200 with default origin" do
        result = lambda_handler(event: event, context: context)

        expect(result[:statusCode]).to eq(200)
        expect(result[:headers]["Access-Control-Allow-Origin"]).to eq("https://smalruby.app")
      end
    end
  end
end