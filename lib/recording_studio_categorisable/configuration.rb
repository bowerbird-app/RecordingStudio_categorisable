# frozen_string_literal: true

module RecordingStudioCategorisable
  class Configuration
    attr_reader :hooks, :category_holder_types

    def initialize
      @category_holder_types = []
      @hooks = RecordingStudio::Hooks.new
    end

    def category_holder_types=(types)
      @category_holder_types = Array(types).map { |type| RecordingStudio.recordable_type_name(type) }.compact.uniq
    end
  end
end
