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
                :reference_capabilities,
                :expected_category_groups,
                :scoped_category_group_capabilities,
                :scoped_category_item_capabilities

    def initialize
      @ui_title = "Categories"
      @hooks = Hooks.new
      @categorisable_registrations = {}
      @category_definitions = []
      @category_group_capabilities = {}
      @category_item_capabilities = {}
      @scoped_category_group_capabilities = Hash.new { |hash, key| hash[key] = {} }
      @scoped_category_item_capabilities = Hash.new { |hash, key| hash[key] = {} }
      @reference_capabilities = {}
      @expected_category_groups = {}
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

    def enable_category_group(*args, key: nil, name: nil, allow: {}, access: :edit, root_recordable_type: nil,
                              **options)
      legacy_options = args.extract_options!
      key ||= args[0]
      name ||= args[1]

      if legacy_options.present?
        allow = legacy_options.fetch(:allow, allow)
        access = legacy_options.fetch(:access, access)
        root_recordable_type = legacy_options.fetch(:root_recordable_type, root_recordable_type)
        options = legacy_options.except(:allow, :access, :root_recordable_type).merge(options)
      end

      raise ArgumentError, "missing keyword: key" if key.blank?
      raise ArgumentError, "missing keyword: name" if name.blank?

      group_key = key.to_s
      normalized_root_type = normalize_recordable_type(root_recordable_type)

      capability = {
        key: group_key,
        name: name.to_s,
        access: (access || :edit).to_sym,
        allow: normalize_allow(
          allow,
          defaults: {
            rename: false,
            update_description: false,
            update_key: false
          }
        )
      }.merge(options.compact)

      category_group_capabilities[group_key] = capability
      scoped_category_group_capabilities[group_key][normalized_root_type] = capability if normalized_root_type.present?

      expected_group = expected_category_groups[group_key] ||= {
        key: group_key,
        name: name.to_s,
        root_recordable_types: []
      }
      expected_group[:name] = name.to_s if expected_group[:name].blank?

      return unless normalized_root_type.present?

      expected_group[:root_recordable_types] |= [normalized_root_type]
    end

    def category_group_capability_for(key, root_recordable_type: nil)
      group_key = key.to_s
      normalized_root_type = normalize_recordable_type(root_recordable_type)

      if normalized_root_type.present?
        scoped = scoped_category_group_capabilities[group_key][normalized_root_type]
        return scoped if scoped.present?
      end

      category_group_capabilities[group_key]
    end

    def enable_category_items(*args, group_key: nil, allow: {}, root_recordable_type: nil, **options)
      legacy_options = args.extract_options!
      group_key ||= args[0]

      if legacy_options.present?
        allow = legacy_options.fetch(:allow, allow)
        root_recordable_type = legacy_options.fetch(:root_recordable_type, root_recordable_type)
        options = legacy_options.except(:allow, :root_recordable_type).merge(options)
      end

      raise ArgumentError, "missing keyword: group_key" if group_key.blank?

      normalized_group_key = group_key.to_s
      normalized_root_type = normalize_recordable_type(root_recordable_type)

      capability = {
        group_key: normalized_group_key,
        allow: normalize_allow(
          allow,
          defaults: {
            create: false,
            update_name: false,
            update_description: false,
            orderable: false,
            delete: false
          }
        )
      }.merge(options.compact)

      if RecordingStudioCategorisable::OrderableSupport.orderable_enabled?(capability)
        RecordingStudioCategorisable::OrderableSupport.ensure_category_group_ordering!(normalized_group_key)
      end

      category_item_capabilities[normalized_group_key] = capability
      return unless normalized_root_type.present?

      scoped_category_item_capabilities[normalized_group_key][normalized_root_type] =
        capability
    end

    def category_item_capability_for(group_key, root_recordable_type: nil)
      normalized_group_key = group_key.to_s
      normalized_root_type = normalize_recordable_type(root_recordable_type)

      if normalized_root_type.present?
        scoped = scoped_category_item_capabilities[normalized_group_key][normalized_root_type]
        return scoped if scoped.present?
      end

      category_item_capabilities[normalized_group_key]
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

      # Also register the category group as expected so auto-seeding creates it.
      group_key = category_group_key.to_s
      expected_group = expected_category_groups[group_key] ||= {
        key: group_key,
        name: options[:label].presence || group_key.titleize,
        root_recordable_types: []
      }

      normalized_root_type = normalize_recordable_type(recordable)
      expected_group[:root_recordable_types] |= [normalized_root_type] if normalized_root_type.present?

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

    def category_definitions_for(root_recordable_type: nil)
      definitions = Array(category_definitions)
      return definitions if root_recordable_type.blank?

      normalized_root_type = normalize_recordable_type(root_recordable_type)

      definitions.select do |definition|
        expected_group = expected_category_groups[definition[:group_key].to_s]
        next false if expected_group.blank?

        allowed_root_types = Array(expected_group[:root_recordable_types]).map(&:to_s)
        allowed_root_types.empty? || allowed_root_types.include?(normalized_root_type)
      end
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

    def normalize_recordable_type(recordable_type)
      return if recordable_type.blank?

      recordable_type.is_a?(Class) ? recordable_type.name : recordable_type.to_s
    end
  end
end
