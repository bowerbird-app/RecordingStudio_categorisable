# frozen_string_literal: true

# Migration to create the category_items table for the RecordingStudioCategorisable engine.
#
# Category items are individual items within a category group. They hang off their
# parent category group recording via RecordingStudio and can be assigned to target recordables.
#
class CreateRecordingStudioCategorisableCategoryItems < ActiveRecord::Migration[8.1]
  def change
    create_table :recording_studio_categorisable_category_items, id: :uuid do |t|
      t.string :label, null: false
      t.text :description
      t.string :color
      t.integer :position, default: 0, null: false
      t.jsonb :metadata, default: {}, null: false

      t.timestamps
    end

    add_index :recording_studio_categorisable_category_items, :label
    add_index :recording_studio_categorisable_category_items, :position
  end
end
