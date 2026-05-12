# frozen_string_literal: true

class CreateRecordingStudioCategorisableCategoryItems < ActiveRecord::Migration[8.1]
  def change
    create_table :recording_studio_categorisable_category_items, id: :uuid do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.integer :position, default: 0, null: false

      t.timestamps
    end

    add_index :recording_studio_categorisable_category_items, :slug
    add_index :recording_studio_categorisable_category_items, :position
    add_index :recording_studio_categorisable_category_items, :name
  end
end
