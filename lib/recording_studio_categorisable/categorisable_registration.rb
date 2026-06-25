# frozen_string_literal: true

module RecordingStudioCategorisable
  class CategorisableRegistration
    attr_reader :recordable_type_name

    def initialize(recordable_type)
      @recordable_type_name = recordable_type.is_a?(Class) ? recordable_type.name : recordable_type.to_s
      @fields = []
    end

    def single_select(attribute_name, **)
      add_field(attribute_name, selection: :single, **)
    end

    def multi_select(attribute_name, **)
      add_field(attribute_name, selection: :multiple, **)
    end

    def add_field(attribute_name = nil, field = nil, **)
      field ||= CategoryField.new(attribute_name: attribute_name, **)
      @fields.reject! { |existing_field| existing_field.key == field.key }
      @fields << field
      field
    end

    def field(attribute_name)
      @fields.find { |existing_field| existing_field.key == attribute_name.to_sym }
    end

    def fields
      @fields.dup
    end

    def recordable_class
      recordable_type_name.safe_constantize
    end

    def current_recordings
      RecordingStudio::Recording.of_type(recordable_type_name)
    end

    def fields_for(recordable)
      fields.select do |field|
        recordable.respond_to?(field.attribute_name) || recordable.respond_to?("#{field.attribute_name}=")
      end
    end
  end
end
