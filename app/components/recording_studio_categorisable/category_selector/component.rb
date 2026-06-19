# frozen_string_literal: true

module RecordingStudioCategorisable
  module CategorySelector
    class Component < FlatPack::BaseComponent
      def initialize(name:, field:, recordable:, item_recordings:, label: nil, error: nil, placeholder: nil, **system_arguments)
        super(**system_arguments)
        @name = name
        @field = field
        @recordable = recordable
        @item_recordings = item_recordings
        @label = label
        @error = error
        @placeholder = placeholder
      end

      def call
        render FlatPack::Select::Component.new(
          name: @name,
          label: label,
          options: options,
          value: value,
          placeholder: placeholder,
          searchable: true,
          multiple: @field.multiple?,
          error: @error,
          **@system_arguments
        )
      end

      private

      def label
        @label || @field.label
      end

      def placeholder
        @placeholder || "Select #{label.to_s.downcase}"
      end

      def value
        @field.multiple? ? Array(@field.read(@recordable)) : @field.read(@recordable)
      end

      def options
        @item_recordings.map do |item_recording|
          [item_recording.recordable.name, item_recording.id]
        end
      end
    end
  end
end
