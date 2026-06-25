class CreateRecordingStudioCategorisableCategoryGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :recording_studio_categorisable_category_groups, id: :uuid do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description

      t.timestamps
    end

    add_index :recording_studio_categorisable_category_groups, :slug
    add_index :recording_studio_categorisable_category_groups, :name
  end
end
