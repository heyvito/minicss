# frozen_string_literal: true

require "minicss"
require "debug"
require "json"

Dir[File.join(__dir__, "support/**")].each { require_relative it }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include FixturePath
  config.extend FixturePath
  config.include CSSParsingTestHelpers
end
