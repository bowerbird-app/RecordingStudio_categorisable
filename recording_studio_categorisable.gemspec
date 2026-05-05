# frozen_string_literal: true

require_relative "lib/recording_studio_categorisable/version"

Gem::Specification.new do |spec|
  spec.name        = "recording_studio_categorisable"
  spec.version     = RecordingStudioCategorisable::VERSION
  spec.authors     = ["Bowerbird"]
  spec.homepage    = "https://github.com/bowerbird-app/RecordingStudio_categorisable"
  spec.summary     = "Category management addon for RecordingStudio"
  spec.description = "A Rails engine addon for RecordingStudio providing category groups, items, " \
                     "and assignments with full CRUD operations and flexible categorization capabilities"
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/bowerbird-app/RecordingStudio_categorisable"
  spec.metadata["changelog_uri"] = "https://github.com/bowerbird-app/RecordingStudio_categorisable/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", "~> 8.1.0"
end
