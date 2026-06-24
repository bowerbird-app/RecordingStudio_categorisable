# frozen_string_literal: true

class MakeCategoryGroupKeyIndexNonUnique < ActiveRecord::Migration[8.1]
  def up
    remove_index :recording_studio_categorisable_category_groups, :key if index_exists?(
      :recording_studio_categorisable_category_groups,
      :key,
      unique: true
    )

    add_index :recording_studio_categorisable_category_groups, :key unless index_exists?(
      :recording_studio_categorisable_category_groups,
      :key,
      unique: false
    )
  end

  def down
    remove_index :recording_studio_categorisable_category_groups, :key if index_exists?(
      :recording_studio_categorisable_category_groups,
      :key,
      unique: false
    )

    add_index :recording_studio_categorisable_category_groups, :key, unique: true unless index_exists?(
      :recording_studio_categorisable_category_groups,
      :key,
      unique: true
    )
  end
end
