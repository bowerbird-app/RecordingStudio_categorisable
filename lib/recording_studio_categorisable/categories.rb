# frozen_string_literal: true

module RecordingStudioCategorisable
  module_function

  def record_category(parent_recording:, name:, actor:)
    cleaned = name.to_s.strip
    raise ArgumentError, "Add a name for this category." if cleaned.empty?

    Access.authorize!(actor: actor, recording: parent_recording, role: :edit)
    root = parent_recording.root_recording_or_self
    root.record(Category, actor: actor, parent_recording: parent_recording) do |category|
      category.name = cleaned
    end
  end

  def recordings_in_category(category_recording)
    ids = category_ids_under(category_recording)
    return RecordingStudio::Recording.none if ids.empty?

    parent_ids = assignment_recordings(ids).pluck(:parent_recording_id)
    RecordingStudio::Recording.kept.where(id: parent_ids)
  end

  def category_ids_under(category_recording)
    category_recording.self_and_descendants.filter_map do |recording|
      recording.id if recording.recordable_type == Category.name
    end
  end

  def assignment_recordings(category_ids)
    choices = RecordingStudio::Recording.connection.quote_table_name(Assignment.table_name)
    recordings = RecordingStudio::Recording.connection.quote_table_name(RecordingStudio::Recording.table_name)
    RecordingStudio::Recording.kept
                              .where(recordable_type: Assignment.name)
                              .joins("INNER JOIN #{choices} ON #{choices}.id = #{recordings}.recordable_id")
                              .where(choices => { category_recording_id: category_ids })
  end
end
