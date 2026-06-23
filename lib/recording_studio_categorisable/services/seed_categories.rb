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
    #         key: "page-status",
    #         name: "Page Status",
    #         description: "Single-select lifecycle state.",
    #         items: [
    #           { key: "draft", name: "Draft", position: 1 },
    #           { key: "published", name: "Published", position: 2 }
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

        @category_definitions.each do |definition|
          group_result = ensure_category_group(definition)
          created << group_result if group_result

          next unless group_result

          Array(definition[:items]).each do |item_definition|
            item_result = ensure_category_item(group_result, item_definition)
            created << item_result if item_result
          end
        end

        success(created)
      end

      def ensure_category_group(definition)
        key = definition[:key].to_s
        name = definition[:name].to_s
        return nil if key.empty? || name.empty?

        existing = find_group_by_key(key)
        return nil if existing

        group_recording = @root_recording.record(RecordingStudioCategorisable::CategoryGroup) do |group|
          group.key = key
          group.name = name
          group.description = definition[:description].presence
        end

        group_recording
      rescue ::ActiveRecord::RecordInvalid => error
        # Another root can attempt the same key in the same boot cycle.
        # Treat duplicate key as already-seeded to keep seeding idempotent.
        return nil if duplicate_group_key_error?(error)

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
          item.position = item_definition[:position] || 0
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
    end
  end
end