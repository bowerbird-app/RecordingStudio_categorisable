# frozen_string_literal: true

class CreateRecordingStudioCategorisableCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :recording_studio_categorisable_categories, id: :uuid do |t|
      t.string :name, null: false
    end
  end
end
