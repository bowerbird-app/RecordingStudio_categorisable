# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module RecordingStudioCategorisable
  module Generators
    class MigrationsGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.expand_path("../../../..", __dir__)

      desc "Copy category migrations into the host application"

      class_option :skip_existing, type: :boolean, default: true,
                                   desc: "Skip migrations that already exist (based on name, ignoring timestamp)"

      def copy_migrations
        migrations_dir = File.join(self.class.source_root, "db", "migrate")
        migration_files = Dir.glob(File.join(migrations_dir, "*.rb"))

        if migration_files.empty?
          say "No category migrations found.", :yellow
          return
        end

        migration_files.each do |source_path|
          migration_name = File.basename(source_path).sub(/^\d+_/, "")
          if options[:skip_existing] && migration_exists?(migration_name)
            say "  skip  #{migration_name} (already exists)", :yellow
            next
          end

          destination = File.join("db/migrate", "#{next_migration_number}_#{migration_name}")
          copy_file source_path, destination
          sleep 0.1
        end

        say "Run bin/rails db:migrate to apply the category tables.", :green
      end

      private

      def migration_exists?(migration_name)
        Dir.glob(File.join(destination_root, "db/migrate", "*_#{migration_name}")).any?
      end

      def next_migration_number
        ActiveRecord::Migration.next_migration_number(Time.now.utc.strftime("%Y%m%d%H%M%S"))
      end
    end
  end
end
