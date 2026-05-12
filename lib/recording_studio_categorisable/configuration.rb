# frozen_string_literal: true

require_relative "hooks"

module RecordingStudioCategorisable
  class Configuration
    attr_accessor :ui_title, :root_recording_resolver
    attr_reader :hooks, :categorisable_registrations

    def initialize
      @ui_title = "Categories"
      @hooks = Hooks.new
      @categorisable_registrations = {}
      @root_recording_resolver = lambda do |controller|
        if controller.respond_to?(:current_root_recording, true)
          controller.send(:current_root_recording)
        elsif defined?(RecordingStudio::Recording)
          RecordingStudio::Recording.unscoped.find_by(parent_recording_id: nil)
        end
      end
    end

    def to_h
      {
        ui_title: ui_title,
        categorisable_registrations: categorisable_registrations.keys.sort,
        hooks_registered: hooks.instance_variable_get(:@registry).transform_values(&:size)
      }
    end

    def register_categorisable(recordable_type)
      registration_key = recordable_type.is_a?(Class) ? recordable_type.name : recordable_type.to_s
      registration = categorisable_registrations[registration_key] ||= CategorisableRegistration.new(registration_key)
      yield(registration) if block_given?
      registration
    end

    def registration_for(recordable_type)
      registration_key = recordable_type.is_a?(Class) ? recordable_type.name : recordable_type.to_s
      categorisable_registrations[registration_key]
    end

    def resolve_root_recording(controller)
      root_recording_resolver&.call(controller)
    end

    def merge!(hash)
      return unless hash.respond_to?(:each)

      hash.each do |k, v|
        key = k.to_s
        setter = "#{key}="
        public_send(setter, v) if respond_to?(setter)
      end
    end
  end
end
