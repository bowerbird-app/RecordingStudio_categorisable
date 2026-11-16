# frozen_string_literal: true

class CreateRecordingStudioCategorisableAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :recording_studio_categorisable_assignments, id: :uuid do |t|
      t.uuid :category_recording_id
      t.index :category_recording_id
    end
  end
end
