# frozen_string_literal: true

class CreateRecordingStudioCategorisableCategoryGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :recording_studio_categorisable_category_groups, id: :uuid do |t|
      t.string :label, null: false
      t.text :description
      t.integer :position, default: 0, null: false
      t.jsonb :metadata, default: {}, null: false

      t.timestamps
    end

    add_index :recording_studio_categorisable_category_groups, :label
    add_index :recording_studio_categorisable_category_groups, :position
  end
end
