# frozen_string_literal: true

class RenameSlugToKeyInCategoryGroupsAndItems < ActiveRecord::Migration[8.1]
  def change
    # Category Groups: rename slug → key, make unique
    rename_column :recording_studio_categorisable_category_groups, :slug, :key
    remove_index :recording_studio_categorisable_category_groups, :slug if index_exists?(:recording_studio_categorisable_category_groups, :slug)
    add_index :recording_studio_categorisable_category_groups, :key, unique: true

    # Category Items: rename slug → key
    rename_column :recording_studio_categorisable_category_items, :slug, :key
    remove_index :recording_studio_categorisable_category_items, :slug if index_exists?(:recording_studio_categorisable_category_items, :slug)
    add_index :recording_studio_categorisable_category_items, :key
  end
end