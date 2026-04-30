# frozen_string_literal: true

# Project model - a categorisable recordable for demonstration purposes.
# Projects can be categorized using the RecordingStudioCategorisable addon.
#
class Project < ApplicationRecord
  include RecordingStudioCategorisable::Categorisable

  validates :name, presence: true, length: { maximum: 255 }
  validates :status, presence: true, inclusion: { in: %w[active archived] }
end
