class HomeController < ApplicationController
  def index
    @workspace = current_workspace
    @root_recording = current_root_recording
    @category_group_count = @root_recording&.recordings_query(
      include_children: true,
      type: RecordingStudioCategorisable::CategoryGroup
    )&.count.to_i
    @page_recordings = @root_recording&.recordings_query(type: Page)&.includes(:recordable)&.to_a || []
  end
end
