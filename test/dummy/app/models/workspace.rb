class Workspace < ApplicationRecord
  include RecordingStudioCategorisable::RecordingBacked

  validates :name, presence: true, length: { maximum: 255 }
end
