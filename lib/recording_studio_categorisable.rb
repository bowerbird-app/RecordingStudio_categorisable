# frozen_string_literal: true

require "recording_studio_categorisable/version"
require "recording_studio_categorisable/engine"
require "recording_studio_categorisable/configuration"
require "recording_studio_categorisable/hooks"
require "recording_studio_categorisable/services/base_service"
require "recording_studio_categorisable/services/example_service"

module RecordingStudioCategorisable
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration) if block_given?
    end
  end
end
