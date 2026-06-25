# frozen_string_literal: true

source "https://rubygems.org"

gem "flat_pack", github: "bowerbird-app/flatpack", tag: "v0.1.106"
gem "recording_studio", github: "bowerbird-app/RecordingStudio", tag: "recording_studio/v3.0.0"
gem "recording_studio_accessible", github: "bowerbird-app/RecordingStudio_accessible", tag: "0.3.2"
gem "recording_studio_orderable",
    github: "bowerbird-app/RecordingStudio_orderable",
    branch: "copilot/create-recordingstudio-orderable"

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
