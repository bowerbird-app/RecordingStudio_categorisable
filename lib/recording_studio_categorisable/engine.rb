# frozen_string_literal: true

module RecordingStudioCategorisable
  class Engine < ::Rails::Engine
    isolate_namespace RecordingStudioCategorisable
    class << self
      def apply_model_extensions(target)
        extensions = RecordingStudioCategorisable.configuration.hooks.model_extensions_for(extension_keys_for(target))
        apply_extensions(target, extensions)
      end

      def apply_controller_extensions(target)
        extensions = RecordingStudioCategorisable.configuration.hooks
                                                 .controller_extensions_for(extension_keys_for(target))
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

      def load_yaml_configuration(app)
        return unless app.respond_to?(:config_for)

        yaml = begin
          app.config_for(:recording_studio_categorisable)
        rescue StandardError
          nil
        end
        RecordingStudioCategorisable.configuration.merge!(yaml) if yaml.respond_to?(:each)
      rescue StandardError => e
        log_configuration_warning("config_for(:recording_studio_categorisable)", e)
      end

      def load_x_configuration(app)
        return unless app.config.respond_to?(:x) && app.config.x.respond_to?(:recording_studio_categorisable)

        xcfg = app.config.x.recording_studio_categorisable
        if xcfg.respond_to?(:to_h)
          RecordingStudioCategorisable.configuration.merge!(xcfg.to_h)
        else
          load_x_configuration_from_each_pair(xcfg)
        end
      rescue StandardError => e
        log_configuration_warning("config.x.recording_studio_categorisable", e)
      end

      def load_x_configuration_from_each_pair(xcfg)
        hash = {}
        xcfg.each_pair { |key, value| hash[key] = value } if xcfg.respond_to?(:each_pair)
        RecordingStudioCategorisable.configuration.merge!(hash) if hash.any?
      rescue StandardError => e
        log_configuration_warning("config.x.recording_studio_categorisable", e)
      end

      def log_configuration_warning(source, error)
        return unless defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger

        Rails.logger.warn(
          "[RecordingStudioCategorisable] Failed to load #{source}: #{error.class}: #{error.message}"
        )
      end
    end

    initializer "recording_studio_categorisable.before_initialize",
                before: "recording_studio_categorisable.load_config" do |_app|
      RecordingStudioCategorisable::Hooks.run(:before_initialize, self)
    end

    initializer "recording_studio_categorisable.load_config" do |app|
      RecordingStudioCategorisable::Engine.send(:load_yaml_configuration, app)
      RecordingStudioCategorisable::Engine.send(:load_x_configuration, app)
      RecordingStudioCategorisable::Hooks.run(:on_configuration, RecordingStudioCategorisable.configuration)
    end

    initializer "recording_studio_categorisable.after_initialize",
                after: "recording_studio_categorisable.load_config" do |_app|
      RecordingStudioCategorisable::Hooks.run(:after_initialize, self)
    end
    initializer "recording_studio_categorisable.optional_integrations",
                after: "recording_studio_categorisable.after_initialize" do
      config.to_prepare do
        RecordingStudioCategorisable.install_optional_integrations!
      end
    end

    initializer "recording_studio_categorisable.apply_model_extensions" do
      config.to_prepare do
        next unless defined?(ActiveRecord::Base)

        ActiveRecord::Base.descendants.each do |model|
          next if model.abstract_class?

          RecordingStudioCategorisable::Engine.apply_model_extensions(model)
        end
      end
    end

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
