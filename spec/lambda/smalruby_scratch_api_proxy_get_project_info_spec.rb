# frozen_string_literal: true

require "spec_helper"

# Load the specific Lambda function
load File.join(__dir__, "../../lambda/smalruby-scratch-api-proxy-get-project-info/lambda_function.rb")

RSpec.describe "smalruby-scratch-api-proxy-get-project-info lambda function" do
  let(:context) { double("context") }
  let(:valid_origin) { "https://smalruby.app" }

  describe "lambda_handler" do
    context "with valid project ID" do
      let(:project_id) { "123456789" }
      let(:event) do
        {
          "headers" => {"origin" => valid_origin},
          "pathParameters" => {"projectId" => project_id}
        }
      end

      let(:scratch_response) do
        {
          "id" => 123456789,
          "title" => "Test Project",
          "description" => "A test project",
          "instructions" => "Click the green flag to start",
          "visibility" => "visible",
          "public" => true,
          "stats" => {
            "views" => 1000,
            "loves" => 50,
            "favorites" => 25
          }
        }.to_json
      end

      before do
        stub_request(:get, "https://api.scratch.mit.edu/projects/#{project_id}")
          .to_return(
            status: 200,
            body: scratch_response,
            headers: {"Content-Type" => "application/json"}
          )
      end

      it "returns project information from Scratch API" do
        result = lambda_handler(event: event, context: context)

        expect(result[:statusCode]).to eq(200)
        expect(result[:headers]["Access-Control-Allow-Origin"]).to eq(valid_origin)
        expect(result[:headers]["Access-Control-Allow-Methods"]).to eq("OPTIONS,GET")

        body = JSON.parse(result[:body])
        expect(body["id"]).to eq(123456789)
        expect(body["title"]).to eq("Test Project")
        expect(body["stats"]["views"]).to eq(1000)
      end
    end

    context "with non-existent project ID" do
      let(:project_id) { "999999999" }
      let(:event) do
        {
          "headers" => {"origin" => valid_origin},
          "pathParameters" => {"projectId" => project_id}
        }
      end

      before do
        stub_request(:get, "https://api.scratch.mit.edu/projects/#{project_id}")
          .to_return(
            status: 404,
            body: "Not found",
            headers: {"Content-Type" => "text/plain"}
          )
      end

      it "returns 200 with not found response from Scratch API" do
        result = lambda_handler(event: event, context: context)

        expect(result[:statusCode]).to eq(200)
        expect(result[:body]).to eq("Not found")
      end
    end

    context "with invalid origin" do
      let(:project_id) { "123456789" }
      let(:event) do
        {
          "headers" => {"origin" => "https://evil.com"},
          "pathParameters" => {"projectId" => project_id}
        }
      end

      before do
        stub_request(:get, "https://api.scratch.mit.edu/projects/#{project_id}")
          .to_return(status: 200, body: '{"id": 123456789}')
      end

      it "uses default origin in CORS headers" do
        result = lambda_handler(event: event, context: context)

        expect(result[:headers]["Access-Control-Allow-Origin"]).to eq("https://smalruby.app")
      end
    end

    context "with missing project ID" do
      let(:event) do
        {
          "headers" => {"origin" => valid_origin},
          "pathParameters" => {}
        }
      end

      before do
        stub_request(:get, "https://api.scratch.mit.edu/projects/")
          .to_return(status: 404, body: "Not found")
      end

      it "handles missing project ID gracefully" do
        result = lambda_handler(event: event, context: context)

        expect(result[:statusCode]).to eq(200)
        expect(result[:body]).to eq("Not found")
      end
    end

    context "when Scratch API is unavailable" do
      let(:project_id) { "123456789" }
      let(:event) do
        {
          "headers" => {"origin" => valid_origin},
          "pathParameters" => {"projectId" => project_id}
        }
      end

      before do
        stub_request(:get, "https://api.scratch.mit.edu/projects/#{project_id}")
          .to_raise(SocketError.new("Connection refused"))
      end

      it "handles network errors gracefully" do
        expect {
          lambda_handler(event: event, context: context)
        }.to raise_error(SocketError, "Connection refused")
      end
    end
  end
end