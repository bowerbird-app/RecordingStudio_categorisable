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

        next unless ActiveRecord::Base.connection.table_exists?(:recording_studio_recordings)

        root_recordings = RecordingStudio::Recording.where(parent_recording_id: nil)
        next if root_recordings.empty?

        root_recordings.find_each do |root_recording|
          definitions = RecordingStudioCategorisable.configuration.category_definitions_for(
            root_recordable_type: root_recording.recordable_type
          )
          next if definitions.blank?

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

    initializer "recording_studio_categorisable.seed_dummy_data",
                after: "recording_studio_categorisable.seed_categories_from_config" do
      config.to_prepare do
        next unless defined?(RecordingStudio)
        next if Rails.env.test?
        next unless ActiveRecord::Base.connection.table_exists?(:recording_studio_recordings)

        # Only seed if no roots exist yet (prevents duplicates on reload)
        next if RecordingStudio::Recording.where(parent_recording_id: nil).exists?

        # Create workspace
        workspace = Workspace.find_or_create_by!(name: "Studio Workspace")
        workspace_root = RecordingStudio::Recording.unscoped.find_or_create_by!(
          recordable: workspace,
          parent_recording_id: nil
        )

        # Create admin root
        admin_root = nil
        admin_root_recording = nil
        if defined?(RecordingStudioAdmin::Admin)
          admin_root = RecordingStudioAdmin::Admin.find_or_create_by!(key: "admin") do |a|
            a.name = "Admin"
          end
          admin_root_recording = RecordingStudio::Recording.unscoped.find_or_create_by!(
            recordable: admin_root,
            parent_recording_id: nil
          )
        end

        # Create sample page under workspace root
        status_group = workspace_root.recordings_query(
          include_children: true,
          type: RecordingStudioCategorisable::CategoryGroup
        ).includes(:recordable).find { |r| r.recordable&.key == "page-status" }

        topics_group = workspace_root.recordings_query(
          include_children: true,
          type: RecordingStudioCategorisable::CategoryGroup
        ).includes(:recordable).find { |r| r.recordable&.key == "page-topics" }

        unless workspace_root.recordings_query(type: Page).exists?
          published_item = status_group&.child_recordings
                                       &.of_type(RecordingStudioCategorisable::CategoryItem)
                                       &.includes(:recordable)
                                       &.find { |r| r.recordable&.key == "published" }
          product_item = topics_group&.child_recordings
                                     &.of_type(RecordingStudioCategorisable::CategoryItem)
                                     &.includes(:recordable)
                                     &.find { |r| r.recordable&.key == "product" }
          studio_item = topics_group&.child_recordings
                                    &.of_type(RecordingStudioCategorisable::CategoryItem)
                                    &.includes(:recordable)
                                    &.find { |r| r.recordable&.key == "studio" }

          workspace_root.record(Page) do |page|
            page.title = "Studio launch plan"
            page.body = "Seeded page for categorisable demo."
            page.status_category_item_recording_id = published_item&.id
            page.topic_category_item_recording_ids = [product_item&.id, studio_item&.id].compact
          end
        end

        unless workspace_root.recordings_query(type: Brief).exists?
          draft_item = status_group&.child_recordings
                                   &.of_type(RecordingStudioCategorisable::CategoryItem)
                                   &.includes(:recordable)
                                   &.find { |r| r.recordable&.key == "draft" }

          workspace_root.record(Brief) do |brief|
            brief.title = "Studio status snapshot"
            brief.body = "Seeded brief for categorisable demo."
            brief.status_category_item_recording_id = draft_item&.id
          end
        end

        # Create access
        admin_user = User.find_by(email: "admin@admin.com")
        viewer_user = User.find_by(email: "viewer@admin.com")

        if admin_user && defined?(RecordingStudioAccessible) && !workspace_root.child_recordings.where(recordable_type: "RecordingStudio::Access").exists?
          begin
            RecordingStudioAccessible::AccessCreationContext.allow do
              workspace_root.record(RecordingStudio::Access, parent_recording: workspace_root) do |a|
                a.actor = admin_user
                a.role = :admin
              end
            end
            if viewer_user
              workspace_root.record(RecordingStudio::Access, parent_recording: workspace_root) do |a|
                a.actor = viewer_user
                a.role = :view
              end
            end
          rescue StandardError => _e
            # access creation is best-effort in dev
          end
        end
      end
    end
  end
end
