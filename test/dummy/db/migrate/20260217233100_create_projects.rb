# frozen_string_literal: true

# Migration to create a Project recordable for demonstrating categorization
# on non-workspace recordables.
#
class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects, id: :uuid do |t|
      t.string :name, null: false
      t.text :description
      t.string :status, default: "active", null: false

      t.timestamps
    end

    add_index :projects, :name
    add_index :projects, :status
  end
end
