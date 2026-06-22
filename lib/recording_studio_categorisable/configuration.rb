# frozen_string_literal: true

require_relative "hooks"

module RecordingStudioCategorisable
  class Configuration
    attr_accessor :ui_title,
                  :root_recording_resolver,
                  :authorization_resolver,
                  :unauthorized_response_handler
    attr_reader :hooks, :categorisable_registrations

    def initialize
      @ui_title = "Categories"
      @hooks = Hooks.new
      @categorisable_registrations = {}
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

    def authorize!(controller)
      unless authorization_resolver
        raise MissingAuthorizationError,
              "Authorization is required for RecordingStudioCategorisable"
      end

      return if authorization_resolver.call(controller)

      raise UnauthorizedError, "You are not authorized to manage categories"
    end

    def handle_unauthorized(controller, exception)
      return false unless unauthorized_response_handler

      unauthorized_response_handler.call(controller, exception)
      controller.performed?
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
