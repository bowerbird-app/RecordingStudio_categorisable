# frozen_string_literal: true

class CreateWorkspaces < ActiveRecord::Migration[8.1]
  def change
    create_table :workspaces, id: :uuid do |t|
      t.string :name, null: false
      t.text :description

      t.timestamps
    end

    add_index :workspaces, :name
  end
end
