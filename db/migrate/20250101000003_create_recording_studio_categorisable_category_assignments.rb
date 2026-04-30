# frozen_string_literal: true

# Migration to create the category_assignments table for the RecordingStudioCategorisable engine.
#
# Category assignments link a category item to a target recordable via RecordingStudio.
# The assignment itself becomes a child recording of the target, and references the
# category item recording via category_item_recording_id.
#
class CreateRecordingStudioCategorisableCategoryAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :recording_studio_categorisable_category_assignments, id: :uuid do |t|
      t.uuid :category_item_recording_id, null: false
      t.jsonb :metadata, default: {}, null: false

      t.timestamps
    end

    add_index :recording_studio_categorisable_category_assignments, :category_item_recording_id,
              name: "idx_cat_assignments_on_item_recording_id"
  end
end
