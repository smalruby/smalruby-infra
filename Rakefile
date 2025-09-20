# frozen_string_literal: true

require "rspec/core/rake_task"

desc "Run Ruby Standard Style linter"
task :standard do
  sh "bundle exec standardrb"
end

desc "Fix Ruby Standard Style issues automatically"
task "standard:fix" do
  sh "bundle exec standardrb --fix"
end

desc "Run all tests"
RSpec::Core::RakeTask.new(:test) do |t|
  t.pattern = "spec/**/*_spec.rb"
  # Set CI environment variable to prevent lambda_handler redefinition warnings
  ENV["CI"] = "true"
end

desc "Run Lambda function tests only"
RSpec::Core::RakeTask.new("test:lambda") do |t|
  t.pattern = "spec/lambda/*_spec.rb"
  # Set CI environment variable to prevent lambda_handler redefinition warnings
  ENV["CI"] = "true"
end

desc "Run lint and tests"
task check: [:standard, :test]

# Default task
task default: :check
