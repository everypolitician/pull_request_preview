ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'

require 'vcr'
VCR.configure do |config|
  config.cassette_library_dir = 'test/vcr_cassettes'
  config.hook_into :webmock
  config.filter_sensitive_data('<GITHUB_ACCESS_TOKEN>') { ENV['GITHUB_ACCESS_TOKEN'] }
end

require_relative '../app'
