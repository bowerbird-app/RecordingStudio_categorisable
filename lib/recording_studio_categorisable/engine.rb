# frozen_string_literal: true

module RecordingStudioCategorisable
  class Engine < ::Rails::Engine
    isolate_namespace RecordingStudioCategorisable

    class << self
      def apply_model_extensions(target)
        hooks = RecordingStudioCategorisable.configuration.hooks
        extensions = hooks.model_extensions_for(extension_keys_for(target))

        apply_extensions(target, extensions)
      end

      def apply_controller_extensions(target)
        hooks = RecordingStudioCategorisable.configuration.hooks
        extensions = hooks.controller_extensions_for(extension_keys_for(target))

        apply_extensions(target, extensions)
      end

      private

      def apply_extensions(target, extensions)
        return unless target

        applied = target.instance_variable_get(:@recording_studio_categorisable_applied_extensions) || identity_hash

        extensions.flatten.compact.each do |extension|
          next if applied[extension]

          target.class_eval(&extension)
          applied[extension] = true
        end

        target.instance_variable_set(:@recording_studio_categorisable_applied_extensions, applied)
      end

      def extension_keys_for(target)
        names = [target.name, target.name&.demodulize].compact.uniq
        names.map(&:to_sym)
      end

      def identity_hash
        {}.compare_by_identity
      end
    end

    # Run before_initialize hooks
    initializer "recording_studio_categorisable.before_initialize",
                before: "recording_studio_categorisable.load_config" do |_app|
      RecordingStudioCategorisable::Hooks.run(:before_initialize, self)
    end

    initializer "recording_studio_categorisable.load_config" do |app|
      # Load config/recording_studio_categorisable.yml via Rails config_for if present
      if app.respond_to?(:config_for)
        begin
          yaml = begin
            app.config_for(:recording_studio_categorisable)
          rescue StandardError
            nil
          end
          RecordingStudioCategorisable.configuration.merge!(yaml) if yaml.respond_to?(:each)
        rescue StandardError => _e
          # ignore load errors; host app can provide initializer overrides
        end
      end

      # Merge Rails.application.config.x.recording_studio_categorisable if present
      if app.config.respond_to?(:x) && app.config.x.respond_to?(:recording_studio_categorisable)
        xcfg = app.config.x.recording_studio_categorisable
        if xcfg.respond_to?(:to_h)
          RecordingStudioCategorisable.configuration.merge!(xcfg.to_h)
        else
          begin
            # try converting OrderedOptions
            hash = {}
            xcfg.each_pair { |k, v| hash[k] = v } if xcfg.respond_to?(:each_pair)
            RecordingStudioCategorisable.configuration.merge!(hash) if hash&.any?
          rescue StandardError => _e
            # ignore
          end
        end
      end

      # Run on_configuration hooks after config is loaded
      RecordingStudioCategorisable::Hooks.run(:on_configuration, RecordingStudioCategorisable.configuration)
    end

    # Run after_initialize hooks
    initializer "recording_studio_categorisable.after_initialize",
                after: "recording_studio_categorisable.load_config" do |_app|
      RecordingStudioCategorisable::Hooks.run(:after_initialize, self)
    end

    initializer "recording_studio_categorisable.seed_categories_from_config",
                after: "recording_studio_categorisable.register_recordable_types" do
      config.to_prepare do
        next unless defined?(RecordingStudio)

        definitions = RecordingStudioCategorisable.category_definitions
        next if definitions.blank?

        root_recordings = RecordingStudio::Recording.where(parent_recording_id: nil)
        next if root_recordings.empty?

        root_recordings.find_each do |root_recording|
          RecordingStudioCategorisable::Services::SeedCategories.call(
            root_recording: root_recording,
            category_definitions: definitions
          )
        end
      end
    end

    initializer "recording_studio_categorisable.register_recordable_types",
                after: "recording_studio_categorisable.after_initialize" do
      config.to_prepare do
        next unless defined?(RecordingStudio)

        category_group_parent_types = RecordingStudio.configuration.recordable_types + [
          "RecordingStudioCategorisable::CategoryGroup"
        ]

        RecordingStudioCategorisable::CategoryGroup.recording_studio_recordable(
          label: "Category group",
          root: false,
          allowed_parent_types: category_group_parent_types
        )

        RecordingStudio.register_recordable_type("RecordingStudioCategorisable::CategoryGroup")

        RecordingStudioCategorisable::CategoryItem.recording_studio_recordable(
          label: "Category item",
          root: false,
          allowed_parent_types: ["RecordingStudioCategorisable::CategoryGroup"]
        )
        RecordingStudio.register_recordable_type("RecordingStudioCategorisable::CategoryItem")
      end
    end

    # Apply model extensions when models are loaded
    initializer "recording_studio_categorisable.apply_model_extensions" do
      config.to_prepare do
        next unless defined?(ActiveRecord::Base)

        ActiveRecord::Base.descendants.each do |model|
          next if model.abstract_class?

          RecordingStudioCategorisable::Engine.apply_model_extensions(model)
        end
      end
    end

    # Apply controller extensions
    initializer "recording_studio_categorisable.apply_controller_extensions" do
      config.to_prepare do
        next unless defined?(ActionController::Base)

        ActionController::Base.descendants.each do |controller|
          RecordingStudioCategorisable::Engine.apply_controller_extensions(controller)
        end
      end
    end
  end
end
