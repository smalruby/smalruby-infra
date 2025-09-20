# frozen_string_literal: true

require "spec_helper"

# Load the specific Lambda function
load File.join(__dir__, "../../lambda/smalruby-mesh-zone-get/lambda_function.rb")

RSpec.describe "smalruby-mesh-zone-get lambda function" do
  let(:context) { double("context") }

  describe "lambda_handler" do
    context "with valid source IP" do
      let(:event) do
        {
          "requestContext" => {
            "identity" => {
              "sourceIp" => "192.168.1.100"
            }
          }
        }
      end

      it "returns 200 with generated domain" do
        result = SmalrubyMeshZoneGet.lambda_handler(event: event, context: context)

        expect(result[:statusCode]).to eq(200)
        expect(result[:headers]).to include("Access-Control-Allow-Origin": "*")
        expect(result[:headers]).to include("Access-Control-Allow-Methods": "OPTIONS,GET")
        expect(result[:headers]).to include("Access-Control-Allow-Headers": "Content-Type")

        body = JSON.parse(result[:body])
        expect(body).to have_key("domain")
        expect(body["domain"]).to be_a(String)
        expect(body["domain"]).to match(/\A[0-9a-f]+\z/)
      end

      it "generates consistent domain for same IP" do
        result1 = lambda_handler(event: event, context: context)
        result2 = lambda_handler(event: event, context: context)

        body1 = JSON.parse(result1[:body])
        body2 = JSON.parse(result2[:body])

        expect(body1["domain"]).to eq(body2["domain"])
      end

      it "generates different domains for different IPs" do
        event1 = {
          "requestContext" => {
            "identity" => {
              "sourceIp" => "192.168.1.100"
            }
          }
        }

        event2 = {
          "requestContext" => {
            "identity" => {
              "sourceIp" => "192.168.1.101"
            }
          }
        }

        result1 = SmalrubyMeshZoneGet.lambda_handler(event: event1, context: context)
        result2 = SmalrubyMeshZoneGet.lambda_handler(event: event2, context: context)

        body1 = JSON.parse(result1[:body])
        body2 = JSON.parse(result2[:body])

        expect(body1["domain"]).not_to eq(body2["domain"])
      end
    end

    context "with missing source IP" do
      let(:event) do
        {
          "requestContext" => {
            "identity" => {}
          }
        }
      end

      it "uses 'none' as default and generates domain" do
        result = SmalrubyMeshZoneGet.lambda_handler(event: event, context: context)

        expect(result[:statusCode]).to eq(200)

        body = JSON.parse(result[:body])
        expect(body).to have_key("domain")
        expect(body["domain"]).to be_a(String)
      end
    end

    context "with missing requestContext" do
      let(:event) { {} }

      it "uses 'none' as default and generates domain" do
        result = SmalrubyMeshZoneGet.lambda_handler(event: event, context: context)

        expect(result[:statusCode]).to eq(200)

        body = JSON.parse(result[:body])
        expect(body).to have_key("domain")
        expect(body["domain"]).to be_a(String)
      end
    end
  end
end
