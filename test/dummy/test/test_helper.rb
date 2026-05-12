ENV["RAILS_ENV"] ||= "test"

require_relative "../config/environment"
require "rails/test_help"
require "devise/test/integration_helpers"

load Rails.root.join("db/seeds.rb")

class ActiveSupport::TestCase
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
