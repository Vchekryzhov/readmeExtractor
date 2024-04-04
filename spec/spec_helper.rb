# frozen_string_literal: true

require 'simplecov'
SimpleCov.start 'rails' do
  add_filter 'spec/'
  add_filter '.github/'
  add_filter 'lib/readmeExtractor/version.rb'
end

require "readmeExtractor"

TO_DIRECTORY = "spec/fixtures/output/"
RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"
  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!
  config.after(:each) do
    FileUtils.rm_rf(Dir.glob("#{TO_DIRECTORY}/*"))
  end
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
