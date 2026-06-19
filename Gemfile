# frozen_string_literal: true

source "https://rubygems.org"

gem "flat_pack", github: "bowerbird-app/flatpack", tag: "v0.1.106"
gem "recording_studio", github: "bowerbird-app/RecordingStudio", tag: "recording_studio/v3.0.0"

# Specify your gem's dependencies in recording_studio_categorisable.gemspec
gemspec

gem "puma"
gem "sprockets-rails"

group :development, :test do
  gem "debug"
  gem "simplecov", require: false
end

group :development do
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
end
