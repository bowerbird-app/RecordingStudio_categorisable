# frozen_string_literal: true

module RecordingStudioCategorisable
  module Services
    # Idempotently creates CategoryGroup and CategoryItem recordings from
    # the host application's category_definitions configuration.
    #
    # Skips any group or item whose +key+ already exists, including a trashed
    # recording tombstone left behind by a prior delete.
    #
    # @example
    #   RecordingStudioCategorisable::Services::SeedCategories.call(
    #     root_recording: root_recording,
    #     category_definitions: [
    #       {
    #         group_key: "page-status",
    #         group_name: "Page Status",
    #         group_description: "Single-select lifecycle state.",
    #         items: [
    #           { key: "draft", name: "Draft" },
    #           { key: "published", name: "Published" }
    #         ]
    #       }
    #     ]
    #   )
    #
    class SeedCategories < BaseService
      def initialize(root_recording:, category_definitions:)
        @root_recording = root_recording
        @category_definitions = Array(category_definitions)
      end

      private

      def perform
        return success([]) if @category_definitions.empty?

        created = []

        @root_recording.with_lock do
          @category_definitions.each do |definition|
            existing_group = find_group_by_key(definition[:group_key].to_s)
            group_result = existing_group || ensure_category_group(definition)
            created << group_result if group_result && existing_group.blank?

            next unless group_result

            Array(definition[:items]).each do |item_definition|
              item_result = ensure_category_item(group_result, item_definition)
              created << item_result if item_result
            end
          end
        end

        success(created)
      end

      def ensure_category_group(definition)
        key = definition[:group_key].to_s
        name = definition[:group_name].to_s
        return nil if key.empty? || name.empty?

        existing = find_group_by_key(key)
        return nil if existing

        @root_recording.record(RecordingStudioCategorisable::CategoryGroup) do |group|
          group.key = key
          group.name = name
          group.description = definition[:group_description].presence
        end
      rescue StandardError => e
        if record_invalid_error?(e)
          # Another root can attempt the same key in the same boot cycle.
          # Treat duplicate key as already-seeded to keep seeding idempotent.
          return nil if duplicate_group_key_error?(e)

          raise
        end

        # During boot/migration transitions, treat duplicate-key races as seeded.
        return nil if record_not_unique_error?(e)

        raise
      end

      def ensure_category_item(group_recording, item_definition)
        key = item_definition[:key].to_s
        name = item_definition[:name].to_s
        return nil if key.empty? || name.empty?

        existing = find_item_by_key(group_recording, key)
        return nil if existing

        @root_recording.record(RecordingStudioCategorisable::CategoryItem, parent_recording: group_recording) do |item|
          item.key = key
          item.name = name
          item.description = item_definition[:description].presence
        end
      end

      def find_group_by_key(key)
        @root_recording
          .recordings_query(include_children: true, type: RecordingStudioCategorisable::CategoryGroup)
          .includes(:recordable)
          .find { |recording| recording.recordable&.key.to_s == key }
      end

      def find_item_by_key(group_recording, key)
        group_recording
          .child_recordings
          .of_type(RecordingStudioCategorisable::CategoryItem)
          .includes(:recordable)
          .find { |recording| recording.recordable&.key.to_s == key }
      end

      def duplicate_group_key_error?(error)
        record = error.respond_to?(:record) ? error.record : nil
        return false unless record.is_a?(RecordingStudioCategorisable::CategoryGroup)

        record.errors.of_kind?(:key, :taken)
      end

      def record_invalid_error?(error)
        error.class.name == "ActiveRecord::RecordInvalid"
      end

      def record_not_unique_error?(error)
        error.class.name == "ActiveRecord::RecordNotUnique"
      end
    end
  end
end
