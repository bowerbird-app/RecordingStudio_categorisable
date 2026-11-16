# frozen_string_literal: true

module RecordingStudioCategorisable
  class Engine < ::Rails::Engine
    isolate_namespace RecordingStudioCategorisable

    initializer "recording_studio_categorisable.view_helpers" do
      ActiveSupport.on_load(:action_view) do
        include RecordingStudioCategorisable::CategoryHelper
      end
    end

    initializer "recording_studio_categorisable.before_initialize",
                before: "recording_studio_categorisable.load_config" do |_app|
      RecordingStudioCategorisable.configuration.hooks.run(:before_initialize, self)
    end

    initializer "recording_studio_categorisable.load_config" do |_app|
      RecordingStudioCategorisable.configuration.hooks.run(
        :on_configuration,
        RecordingStudioCategorisable.configuration
      )
    end

    initializer "recording_studio_categorisable.after_initialize",
                after: "recording_studio_categorisable.load_config" do |_app|
      RecordingStudioCategorisable.configuration.hooks.run(:after_initialize, self)
    end

    initializer "recording_studio_categorisable.prepare_recordables" do
      config.to_prepare do
        RecordingStudioCategorisable.prepare_recordables!
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

    class << self
      def apply_model_extensions(target)
        apply_extensions(target, extensions_for(:model, target))
      end

      def apply_controller_extensions(target)
        apply_extensions(target, extensions_for(:controller, target))
      end

      private

      def extensions_for(kind, target)
        hooks = RecordingStudioCategorisable.configuration.hooks
        extension_keys_for(target).flat_map do |name|
          if kind == :model
            hooks.model_extensions_for(name)
          else
            hooks.controller_extensions_for(name)
          end
        end
      end

      def apply_extensions(target, extensions)
        return unless target

        applied = target.instance_variable_get(:@recording_studio_categorisable_applied_extensions)
        applied ||= {}.compare_by_identity
        extensions.flatten.compact.each do |extension|
          next if applied[extension]

          target.class_eval(&extension)
          applied[extension] = true
        end
        target.instance_variable_set(:@recording_studio_categorisable_applied_extensions, applied)
      end

      def extension_keys_for(target)
        [target.name, target.name&.demodulize].compact.uniq.map(&:to_sym)
      end
    end
  end
end
