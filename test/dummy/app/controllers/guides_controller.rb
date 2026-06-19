class GuidesController < ApplicationController
  def install
  end

  def configuration
    render :config
  end

  def methods
  end

  def components
  end

  def recording_tree
    @root_recording = current_root_recording
    @recording_tree = build_recording_tree(@root_recording) if @root_recording
  end

  private

  def build_recording_tree(recording)
    {
      label: "#{recording.recordable_type.demodulize} - #{recordable_name(recording)}",
      icon: recording_icon(recording),
      meta: nil,
      expanded: true,
      children: child_recordings_for(recording).map { |child_recording| build_recording_tree(child_recording) }
    }
  end

  def child_recordings_for(recording)
    (recording.child_recordings.to_a + direct_access_recordings_for(recording))
      .uniq(&:id)
      .select do |child_recording|
        child_recording.recordable_type == "RecordingStudio::Access" ||
          child_recording.recordable_type.safe_constantize.present?
      end
      .sort_by { |child_recording| [child_recording.recordable_type, recordable_name(child_recording)] }
  end

  def direct_access_recordings_for(recording)
    scope = RecordingStudio::Recording.unscoped
                                    .where(
                                      parent_recording_id: recording.id,
                                      recordable_type: "RecordingStudio::Access"
                                    )
    scope = scope.where(trashed_at: nil) if RecordingStudio::Recording.column_names.include?("trashed_at")

    scope = scope.joins("LEFT JOIN recording_studio_accesses ON recording_studio_accesses.id = recording_studio_recordings.recordable_id")
                 .joins("LEFT JOIN users access_users ON access_users.id = recording_studio_accesses.actor_id AND recording_studio_accesses.actor_type = 'User'")
                 .select(
                   "recording_studio_recordings.*",
                   "recording_studio_accesses.role AS access_role",
                   "recording_studio_accesses.actor_type AS access_actor_type",
                   "recording_studio_accesses.actor_id AS access_actor_id",
                   "access_users.email AS access_actor_email"
                 )

    scope.to_a
  rescue StandardError
    []
  end

  def recording_icon(recording)
    return :home if recording.parent_recording_id.nil?
    return :lock_closed if recording.recordable_type == "RecordingStudio::Access"

    :document
  end

  def recordable_name(recording)
    recordable = recording.recordable
    if recording.recordable_type == "RecordingStudio::Access" && recordable.respond_to?(:actor)
      actor_email = recordable.actor&.respond_to?(:email) ? recordable.actor.email.to_s : ""
      return [recordable.role, actor_email].reject(&:blank?).join(" - ")
    end

    if recording.recordable_type == "RecordingStudio::Access"
      role = recording.attributes["access_role"].to_s
      actor_email = recording.attributes["access_actor_email"].to_s
      actor_type = recording.attributes["access_actor_type"].to_s
      actor_id = recording.attributes["access_actor_id"].to_s
      actor_label = actor_email.presence || [actor_type, actor_id.presence].compact.join("#")

      return [role, actor_label].reject(&:blank?).join(" - ").presence || "Access"
    end

    return recordable.recordable_name if recordable.respond_to?(:recordable_name) && recordable.recordable_name.present?
    return recordable.name if recordable.respond_to?(:name) && recordable.name.present?
    return recordable.title if recordable.respond_to?(:title) && recordable.title.present?

    recording.recordable_type.demodulize
  end
end
