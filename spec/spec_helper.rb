require 'bundler/setup'
require 'factory_bot'
require 'async_task'

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

FactoryBot.definition_file_paths = [
  File.expand_path('../factories', __FILE__),
  File.expand_path('../dummy/spec/factories', __FILE__)
]
FactoryBot.find_definitions
