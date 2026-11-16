# frozen_string_literal: true

require "recording_studio"
require "recording_studio_categorisable/version"
require "recording_studio_categorisable/configuration"
require "recording_studio_categorisable/access"
require "recording_studio_categorisable/categories"
require "recording_studio_categorisable/capabilities/categorisable"
require "recording_studio_categorisable/engine"

module RecordingStudioCategorisable
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration) if block_given?
    end

    def prepare_recordables!
      RecordingStudio.register_recordable_type("RecordingStudioCategorisable::Category")
      RecordingStudio.register_recordable_type("RecordingStudioCategorisable::Assignment")
      RecordingStudio::RecordableDeclarations.install_active_record_macro!
      RecordingStudioCategorisable::Category.sync_declaration!
      RecordingStudioCategorisable::Assignment
    end
  end
end
