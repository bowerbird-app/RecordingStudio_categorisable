class CreateBriefs < ActiveRecord::Migration[8.0]
  def change
    create_table :briefs, id: :uuid do |t|
      t.string :title, null: false
      t.text :body
      t.uuid :status_category_item_recording_id

      t.timestamps
    end

    add_index :briefs, :status_category_item_recording_id
  end
end
