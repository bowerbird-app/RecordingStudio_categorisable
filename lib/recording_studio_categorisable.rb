# frozen_string_literal: true

require "recording_studio_categorisable/version"
require "recording_studio_categorisable/engine"
require "recording_studio_categorisable/configuration"
require "recording_studio_categorisable/hooks"
require "recording_studio_categorisable/recording_backed"
require "recording_studio_categorisable/recording_relations"
require "recording_studio_categorisable/recording_support"
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

    def install_optional_integrations!
      install_trashable_support!
    end

    private

    def install_trashable_support!
      capability = trashable_capability
      return unless capability

      trashable_recordables.each do |recordable|
        recordable.include(capability) unless recordable.included_modules.include?(capability)
      end
    end

    def trashable_capability
      return unless defined?(RecordingStudio::Capabilities::Trashable)

      @trashable_capability ||= RecordingStudio::Capabilities::Trashable.to
    end

    def trashable_recordables
      [
        RecordingStudioCategorisable::CategoryGroup,
        RecordingStudioCategorisable::CategoryItem,
        RecordingStudioCategorisable::CategoryAssignment
      ]
    end
  end
end
