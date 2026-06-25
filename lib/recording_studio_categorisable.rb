# frozen_string_literal: true

require "recording_studio_categorisable/version"
require "recording_studio_categorisable/configuration"
require "recording_studio_categorisable/errors"
require "recording_studio_categorisable/category_field"
require "recording_studio_categorisable/categorisable"
require "recording_studio_categorisable/categorisable_registration"
require "recording_studio_categorisable/recording_visibility"
require "recording_studio_categorisable/usage_report"
require "recording_studio_categorisable/orderable_support"
require "recording_studio_categorisable/capabilities"
require "recording_studio_categorisable/services/base_service"
require "recording_studio_categorisable/services/example_service"
require "recording_studio_categorisable/services/seed_categories"
require "recording_studio_categorisable/engine"

module RecordingStudioCategorisable
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration) if block_given?
    end

    def register_categorisable(recordable_type, &)
      configuration.register_categorisable(recordable_type, &)
    end

    def category_definitions
      configuration.category_definitions
    end

    def category_definitions=(definitions)
      configuration.category_definitions = Array(definitions)
    end
  end
end
