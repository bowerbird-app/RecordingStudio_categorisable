# frozen_string_literal: true

module RecordingStudioCategorisable
  module Capabilities
    module Categorisable
      class << self
        def enable(on:, category_groups: nil, category_items: nil, references: nil)
          RecordingStudio.enable_capability(:categorisable, on: on)

          current_options = RecordingStudio.capability_options(:categorisable, for: on) || {}
          merged_options = merge_options(
            current_options,
            category_groups: category_groups,
            category_items: category_items,
            references: references
          )

          RecordingStudio.set_capability_options(:categorisable, on: on, **merged_options)
          apply_options(on: on, options: merged_options)
        end

        def apply_for(on)
          options = RecordingStudio.capability_options(:categorisable, for: on)
          apply_options(on: on, options: options)
        end

        def sync_all_enabled!
          RecordingStudio.configuration.enabled_recordable_types_for(:categorisable).each do |recordable_type|
            apply_for(recordable_type)
          end
        end

        def register_capability!
          RecordingStudio.register_capability(:categorisable, source: self)
        end

        private

        def apply_options(on:, options:)
          return if options.blank?

          recordable_class = resolve_recordable_class(on)
          root_recordable_type = resolve_recordable_type(on)

          Array(options[:category_groups]).each do |group|
            apply_category_group(group, root_recordable_type: root_recordable_type)
          end

          Array(options[:category_items]).each do |item|
            apply_category_items(item, root_recordable_type: root_recordable_type)
          end

          Array(options[:references]).each do |reference|
            apply_reference(reference, recordable_class: recordable_class)
          end
        end

        def apply_category_group(group, root_recordable_type:)
          return if group.blank?

          key = group.fetch(:key)
          inferred_name = key.to_s.tr("-", " ").titleize

          RecordingStudioCategorisable.configuration.enable_category_group(
            key: key,
            name: group[:name].presence || inferred_name,
            access: group[:access],
            root_recordable_type: group[:root_recordable_type].presence || root_recordable_type,
            allow: group.fetch(:allow, {})
          )
        end

        def apply_category_items(item, root_recordable_type:)
          return if item.blank?

          RecordingStudioCategorisable.configuration.enable_category_items(
            group_key: item.fetch(:group_key),
            root_recordable_type: item[:root_recordable_type].presence || root_recordable_type,
            allow: item.fetch(:allow, {})
          )
        end

        def apply_reference(reference, recordable_class:)
          return if reference.blank? || recordable_class.blank?

          ensure_categorisable!(recordable_class)

          options = reference.dup
          attribute_name = options.delete(:attribute_name)
          category_group_key = options.delete(:category_group_key)
          selection = options.delete(:selection)

          recordable_class.enable_category_reference(
            attribute_name: attribute_name,
            category_group_key: category_group_key,
            selection: selection,
            **options
          )

          RecordingStudioCategorisable.configuration.enable_reference(
            recordable: recordable_class,
            attribute_name: attribute_name,
            category_group_key: category_group_key,
            selection: selection,
            **options
          )
        end

        def ensure_categorisable!(recordable)
          return if recordable < RecordingStudioCategorisable::Categorisable

          recordable.include(RecordingStudioCategorisable::Categorisable)
        end

        def merge_options(current_options, category_groups:, category_items:, references:)
          {
            category_groups: merge_entries(
              current_options[:category_groups],
              category_groups,
              keys: %i[key root_recordable_type]
            ),
            category_items: merge_entries(
              current_options[:category_items],
              category_items,
              keys: %i[group_key root_recordable_type]
            ),
            references: merge_entries(
              current_options[:references],
              references,
              keys: %i[attribute_name]
            )
          }
        end

        def merge_entries(existing_entries, new_entries, keys:)
          merged_entries = Array(existing_entries).map(&:dup)

          Array(new_entries).each do |entry|
            next if entry.blank?

            index = merged_entries.index { |candidate| entry_key(candidate, keys) == entry_key(entry, keys) }
            if index
              merged_entries[index] = merged_entries[index].merge(entry)
            else
              merged_entries << entry
            end
          end

          merged_entries
        end

        def entry_key(entry, keys)
          keys.map { |key| entry[key].to_s }
        end

        def resolve_recordable_class(on)
          return on if on.is_a?(Class)

          on.to_s.safe_constantize
        end

        def resolve_recordable_type(on)
          return on.name if on.is_a?(Class)

          on.to_s
        end
      end
    end
  end
end