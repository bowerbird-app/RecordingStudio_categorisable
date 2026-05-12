# frozen_string_literal: true

module RecordingStudioCategorisable
  class UsageReport
    def initialize(registrations: RecordingStudioCategorisable.configuration.categorisable_registrations.values)
      @registrations = Array(registrations)
      @item_usage_counts = nil
    end

    def item_usage_count(recording_or_id)
      item_usage_counts.fetch(recording_id_for(recording_or_id), 0)
    end

    def group_usage_count(group_recording)
      descendant_item_recordings(group_recording)
        .sum { |item_recording| item_usage_count(item_recording) }
    end

    def in_use?(recording_or_id)
      item_usage_count(recording_or_id).positive?
    end

    def group_in_use?(group_recording)
      group_usage_count(group_recording).positive?
    end

    private

    def item_usage_counts
      @item_usage_counts ||= @registrations.each_with_object(Hash.new(0)) do |registration, counts|
        accumulate_registration_counts(registration, counts)
      end
    end

    def recording_id_for(recording_or_id)
      recording_or_id.respond_to?(:id) ? recording_or_id.id : recording_or_id
    end

    def accumulate_registration_counts(registration, counts)
      return unless registration.recordable_class

      registration.current_recordings.includes(:recordable).find_each do |recording|
        recordable = recording.recordable
        registration.fields_for(recordable).each do |field|
          Array(field.read(recordable)).each do |item_recording_id|
            counts[item_recording_id] += 1
          end
        end
      end
    end

    def descendant_item_recordings(group_recording)
      descendants = []
      queue = group_recording.child_recordings.includes(:recordable).to_a

      until queue.empty?
        recording = queue.shift
        descendants << recording if recording.recordable.is_a?(RecordingStudioCategorisable::CategoryItem)
        queue.concat(recording.child_recordings.includes(:recordable).to_a)
      end

      descendants
    end
  end
end
