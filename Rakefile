# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

DUMMY_GEMFILE = File.expand_path("test/dummy/Gemfile", __dir__)
DUMMY_APP_ROOT = File.expand_path("test/dummy", __dir__)
DUMMY_BUNDLE_CLEARED_ENV = {
  "BUNDLE_APP_CONFIG" => nil,
  "BUNDLE_BIN_PATH" => nil,
  "BUNDLE_GEMFILE" => DUMMY_GEMFILE,
  "BUNDLE_LOCKFILE" => nil,
  "BUNDLER_SETUP" => nil,
  "BUNDLER_VERSION" => nil,
  "RUBYLIB" => nil,
  "RUBYOPT" => nil
}.freeze

def run_command!(env, *command)
  return if Bundler.with_unbundled_env { system(env, *command) }

  raise "Command failed (#{Process.last_status.exitstatus}): #{command.join(' ')}"
end

def dummy_bundle_env
  {
    "BUNDLE_GEMFILE" => DUMMY_GEMFILE,
    "DISABLE_SIMPLECOV" => "true"
  }.merge(DUMMY_BUNDLE_CLEARED_ENV).tap do |env|
    env["BUNDLE_PATH"] = ENV["BUNDLE_PATH"] if ENV["BUNDLE_PATH"]
    env["DATABASE_URL"] = ENV["DATABASE_URL"] if ENV["DATABASE_URL"]
    env["RAILS_MASTER_KEY"] = ENV["RAILS_MASTER_KEY"] if ENV["RAILS_MASTER_KEY"]
  end
end

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"].exclude("test/dummy/**/*_test.rb")
  t.verbose = false
end

namespace :test do
  desc "Run dummy app tests under the dummy app bundle"
  task :dummy do
    Dir.chdir(DUMMY_APP_ROOT) do
      env = dummy_bundle_env
      run_command!(env, "bundle", "exec", "bin/rails", "db:prepare")
      run_command!(env, "bundle", "exec", "bin/rails", "test")
    end
  end

  desc "Run gem and dummy app tests"
  task all: %i[test dummy]
end

namespace :app do
  desc "Run gem tests and the dummy app suite"
  task test: "test:all"
end

task default: :test
