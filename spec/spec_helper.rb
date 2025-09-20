# frozen_string_literal: true

require "webmock/rspec"
require "json"

# Configure RSpec
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.disable_monkey_patching!
  config.warnings = true

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  config.profile_examples = 10
  config.order = :random
  Kernel.srand config.seed
end

# Load Lambda functions individually to avoid conflicts
def load_lambda_function(function_name)
  lambda_file = File.join(__dir__, "../lambda/#{function_name}/lambda_function.rb")

  # Load function in isolation
  module_name = function_name.tr("-", "_").capitalize + "Lambda"
  Object.const_set(module_name, Module.new) unless Object.const_defined?(module_name)

  # Read and eval the function code in module namespace
  code = File.read(lambda_file)
  Object.const_get(module_name).module_eval(code)
end

# WebMock configuration
WebMock.disable_net_connect!(allow_localhost: true)