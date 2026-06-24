class HomeController < ApplicationController
  def index
    @root_recording = current_root_recording
    category_group_recordings = @root_recording
                                &.recordings_query(
                                  include_children: true,
                                  type: RecordingStudioCategorisable::CategoryGroup
                                )
                                &.where(trashed_at: nil)
                                &.includes(:recordable)
                                &.to_a
                                &.select { |recording| recording.recordable.present? }
                                .to_a

    @category_group_count = category_group_recordings
                            .select { |recording| visible_category_group_for_current_root?(recording.recordable.key) }
                            .group_by { |recording| recording.recordable.key.to_s }
                            .count
    @page_recordings = @root_recording&.recordings_query(type: Page)&.includes(:recordable)&.to_a || []
    @brief_recordings = @root_recording&.recordings_query(type: Brief)&.includes(:recordable)&.to_a || []
    @recordable_rows = (@page_recordings + @brief_recordings).sort_by(&:updated_at).reverse
  end
end
