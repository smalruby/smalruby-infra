# frozen_string_literal: true

desc "Run Ruby Standard Style linter"
task :standard do
  sh "bundle exec standardrb"
end

desc "Fix Ruby Standard Style issues automatically"
task "standard:fix" do
  sh "bundle exec standardrb --fix"
end

# Default task
task default: :standard
