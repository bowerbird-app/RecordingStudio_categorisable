# frozen_string_literal: true

module RecordingStudio
  module Capabilities
    module Categorisable
      def self.to(**)
        RecordingStudio::Capabilities.include_for(:categorisable, **)
      end

      module RecordingMethods
        include RecordingStudio::Capability

        def assign_category!(category_recording, actor:)
          assert_capability!(:categorisable)
          assert_category_recording!(category_recording)
          RecordingStudioCategorisable::Access.authorize!(actor: actor, recording: self, role: :edit)
          write_category!(category_recording.id, actor: actor)
          log_event!(
            action: "category_assigned",
            actor: actor,
            metadata: { category_recording_id: category_recording.id }
          )
          self
        end

        def remove_category!(actor:)
          assert_capability!(:categorisable)
          choice = category_choice_recording
          return self if choice.nil? || choice.recordable.category_recording_id.blank?

          RecordingStudioCategorisable::Access.authorize!(actor: actor, recording: self, role: :edit)
          revise(choice, actor: actor) { |row| row.category_recording_id = nil }
          log_event!(action: "category_removed", actor: actor, metadata: {})
          self
        end

        def category_recording
          assert_capability!(:categorisable)
          category_id = category_choice_recording&.recordable&.category_recording_id
          return if category_id.blank?

          self.class.kept.find_by(id: category_id)
        end

        private

        def assert_category_recording!(category_recording)
          return if same_category_root?(category_recording)

          raise ArgumentError, "Choose a category in this workspace."
        end

        def same_category_root?(category_recording)
          return false if category_recording.nil?

          category_recording.recordable_type == RecordingStudioCategorisable::Category.name &&
            root_recording_or_self.id == category_recording.root_recording_or_self.id
        end

        def write_category!(category_id, actor:)
          choice = category_choice_recording
          return revise(choice, actor: actor) { |row| row.category_recording_id = category_id } if choice

          record(RecordingStudioCategorisable::Assignment, actor: actor, parent_recording: self) do |row|
            row.category_recording_id = category_id
          end
        end

        def category_choice_recording
          child_recordings.kept.of_type(RecordingStudioCategorisable::Assignment.name).first
        end
      end
    end
  end
end

RecordingStudio.register_capability(
  :categorisable,
  recording_methods: RecordingStudio::Capabilities::Categorisable::RecordingMethods,
  source: RecordingStudio::Capabilities::Categorisable,
  child_recordables: "RecordingStudioCategorisable::Assignment"
)
