class CreatePages < ActiveRecord::Migration[8.1]
  def change
    create_table :pages, id: :uuid do |t|
      t.string :title, null: false
      t.text :body
      t.uuid :status_category_item_recording_id
      t.uuid :topic_category_item_recording_ids, array: true, default: [], null: false

      t.timestamps
    end

    add_index :pages, :status_category_item_recording_id
    add_index :pages, :topic_category_item_recording_ids, using: :gin
  end
end
