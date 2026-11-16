# frozen_string_literal: true

require_relative "lib/recording_studio_categorisable/version"

Gem::Specification.new do |spec|
  spec.name = "recording_studio_categorisable"
  spec.version = RecordingStudioCategorisable::VERSION
  spec.authors = ["Bowerbird"]
  spec.homepage = "https://github.com/bowerbird-app/RecordingStudio_categorisable"
  spec.summary = "Categories for Recording Studio"
  spec.description = "Add one category to chosen types, nest categories, and filter by them."
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md", "CHANGELOG.md"]
  end

  spec.add_dependency "flat_pack", ">= 0.1.331"
  spec.add_dependency "rails", "~> 8.1.0"
  spec.add_dependency "recording_studio", ">= 7.1", "< 8.0"
end
