# frozen_string_literal: true

require "rails/generators"

module RecordingStudioCategorisable
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Mount categories and register the category recordables"

      class_option :mount_path, type: :string, default: "/categories",
                                desc: "Route prefix used when mounting the engine"

      def mount_engine
        route %(mount RecordingStudioCategorisable::Engine, at: "#{options[:mount_path]}")
      end

      def copy_initializer
        template "recording_studio_categorisable.rb", "config/initializers/recording_studio_categorisable.rb"
      end

      def register_recordable_types
        path = "config/initializers/recording_studio.rb"
        absolute = File.join(destination_root, path)
        return say "Add the category types to config.recordable_types yourself.", :yellow unless File.exist?(absolute)

        contents = File.read(absolute)
        %w[RecordingStudioCategorisable::Category RecordingStudioCategorisable::Assignment].each do |type|
          next if contents.include?(type)

          inject_into_file path, after: /config\.recordable_types\s*=\s*\[/ do
            "\n    \"#{type}\","
          end
          contents = File.read(File.join(destination_root, path))
        end
      end

      def add_tailwind_source
        css_path = Rails.root.join("app/assets/tailwind/application.css")
        unless File.exist?(css_path)
          say "No Tailwind file found. Add the category views to your Tailwind sources.", :yellow
          return
        end

        line = %(@source "#{tailwind_source}";)
        contents = File.read(css_path)
        return if contents.include?(line)

        inject_into_file css_path, "\n#{line}\n", after: "@import \"tailwindcss\";\n"
        say "Added category views to Tailwind. Run bin/rails tailwindcss:build.", :green
      end

      def show_readme
        readme "INSTALL.md" if behavior == :invoke
      end

      private

      def tailwind_source
        views = RecordingStudioCategorisable::Engine.root.join("app/views")
        "#{views.relative_path_from(Rails.root.join('app/assets/tailwind'))}/**/*.erb"
      end
    end
  end
end
