# frozen_string_literal: true

require "recording_studio_categorisable/version"
require "recording_studio_categorisable/engine"
require "recording_studio_categorisable/configuration"

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
