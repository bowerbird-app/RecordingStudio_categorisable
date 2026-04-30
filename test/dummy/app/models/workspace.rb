class Workspace < ApplicationRecord
  validates :name, presence: true, length: { maximum: 255 }

  # Get the RecordingStudio::Recording wrapper for this workspace
  def recording
    @recording ||= RecordingStudio::Recording.find_by(
      recordable_type: self.class.name,
      recordable_id: id
    )
  end
end
