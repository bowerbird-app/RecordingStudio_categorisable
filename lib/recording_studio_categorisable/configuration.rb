# frozen_string_literal: true

require_relative "hooks"

module RecordingStudioCategorisable
  class Configuration
    attr_accessor :ui_title,
                  :root_recording_resolver,
                  :authorization_resolver,
                  :unauthorized_response_handler,
                  :category_definitions
    attr_reader :hooks,
                :categorisable_registrations,
                :category_group_capabilities,
                :category_item_capabilities,
                :reference_capabilities

    def initialize
      @ui_title = "Categories"
      @hooks = Hooks.new
      @categorisable_registrations = {}
      @category_definitions = []
      @category_group_capabilities = {}
      @category_item_capabilities = {}
      @reference_capabilities = {}
    end

    def to_h
      {
        ui_title: ui_title,
        categorisable_registrations: categorisable_registrations.keys.sort,
        category_group_capabilities: category_group_capabilities.keys.sort,
        category_item_capabilities: category_item_capabilities.keys.sort,
        reference_capabilities: reference_capabilities.keys.sort,
        hooks_registered: hooks.instance_variable_get(:@registry).transform_values(&:size)
      }
    end

    def enable_category_group(key:, name:, allow: {}, **options)
      group_key = key.to_s

      category_group_capabilities[group_key] = {
        key: group_key,
        name: name.to_s,
        allow: normalize_allow(
          allow,
          defaults: {
            rename: false,
            reorder: false,
            move: false,
            update_description: false,
            update_key: false
          }
        )
      }.merge(options.compact)
    end

    def category_group_capability_for(key)
      category_group_capabilities[key.to_s]
    end

    def enable_category_items(group_key:, allow: {}, **options)
      normalized_group_key = group_key.to_s

      category_item_capabilities[normalized_group_key] = {
        group_key: normalized_group_key,
        allow: normalize_allow(
          allow,
          defaults: {
            create: false,
            update_name: false,
            update_position: false,
            delete: false
          }
        )
      }.merge(options.compact)
    end

    def category_item_capability_for(group_key)
      category_item_capabilities[group_key.to_s]
    end

    def enable_reference(recordable:, attribute_name:, category_group_key:, selection:, **options)
      registration = register_categorisable(recordable)

      reference = {
        attribute_name: attribute_name.to_sym,
        category_group_key: category_group_key.to_s,
        selection: selection.to_sym
      }.merge(options.compact)

      reference_capabilities[registration.recordable_type_name] ||= []
      reference_capabilities[registration.recordable_type_name].reject! do |existing_reference|
        existing_reference[:attribute_name] == reference[:attribute_name]
      end
      reference_capabilities[registration.recordable_type_name] << reference

      reference
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

    private

    def normalize_allow(allow, defaults:)
      normalized_allow = defaults.dup

      allow.to_h.each do |key, value|
        normalized_allow[key.to_sym] = value
      end

      normalized_allow
    end
  end
end
