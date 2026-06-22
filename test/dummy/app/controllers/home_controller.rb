class HomeController < ApplicationController
  def index
    @root_recording = current_root_recording
    @category_group_count = @root_recording&.recordings_query(
      include_children: true,
      type: RecordingStudioCategorisable::CategoryGroup
    )&.count.to_i
    @page_recordings = @root_recording&.recordings_query(type: Page)&.includes(:recordable)&.to_a || []
    @brief_recordings = @root_recording&.recordings_query(type: Brief)&.includes(:recordable)&.to_a || []
    @recordable_rows = (@page_recordings + @brief_recordings).sort_by(&:updated_at).reverse
  end
end
