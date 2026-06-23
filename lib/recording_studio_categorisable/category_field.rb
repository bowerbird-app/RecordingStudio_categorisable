# frozen_string_literal: true

module RecordingStudioCategorisable
  # rubocop:disable Metrics/ClassLength
  class CategoryField
    GROUP_RECORDINGS_CACHE_IVAR = :@recording_studio_categorisable_group_recordings_by_key
    ITEM_RECORDINGS_CACHE_IVAR = :@recording_studio_categorisable_item_recordings_by_group_id

    SELECTIONS = %i[single multiple].freeze

    attr_reader :attribute_name, :selection, :category_group_key, :group_resolver

    def initialize(attribute_name:, selection:, category_group_key:, **options)
      @attribute_name = attribute_name.to_sym
      @selection = selection.to_sym
      @category_group_key = category_group_key.to_s
      @label = options[:label]
      @value_reader = options[:value_reader]
      @value_writer = options[:value_writer]
      @group_resolver = options[:group_resolver]

      validate!
    end

    def key
      attribute_name
    end

    def label
      @label.presence || attribute_name.to_s.humanize
    end

    def single?
      selection == :single
    end

    def multiple?
      selection == :multiple
    end

    def read(recordable)
      raw_value = if @value_reader
                    @value_reader.call(recordable)
                  else
                    recordable.public_send(attribute_name)
                  end

      single? ? normalize_single(raw_value) : normalize_multiple(raw_value)
    end

    def write(recordable, raw_value)
      value = single? ? normalize_single(raw_value) : normalize_multiple(raw_value)

      if @value_writer
        @value_writer.call(recordable, value)
      else
        recordable.public_send("#{attribute_name}=", value)
      end
    end

    def sanitize(raw_value, root_recording:, recordable: nil)
      normalized = single? ? Array(normalize_single(raw_value)).compact : normalize_multiple(raw_value)
      valid_item_ids = available_item_recordings(root_recording: root_recording, recordable: recordable).map(&:id)
      invalid_item_ids = normalized - valid_item_ids

      raise InvalidCategorySelectionError, "contains invalid category items" if invalid_item_ids.any?
      raise InvalidCategorySelectionError, "allows only one category item" if single? && normalized.size > 1

      single? ? normalized.first : normalized
    end

    def resolve_group_recording(root_recording:, recordable: nil)
      return if root_recording.blank?

      if group_resolver.respond_to?(:call)
        return group_resolver.call(root_recording: root_recording, recordable: recordable, field: self)
      end

      group_recordings = group_recordings_for(root_recording)

      if group_recordings.many?
        raise AmbiguousCategoryGroupError,
              "multiple category groups share key #{category_group_key.inspect}"
      end

      group_recordings.first
    end

    def available_item_recordings(root_recording:, recordable: nil)
      group_recording = resolve_group_recording(root_recording: root_recording, recordable: recordable)
      item_recordings = category_item_recordings_for(group_recording)

      sort_item_recordings(item_recordings)
    end

    private

    def normalize_single(raw_value)
      value = Array(raw_value).flatten.compact.first
      value.presence
    end

    def normalize_multiple(raw_value)
      Array(raw_value).flatten.compact.map(&:presence).compact.uniq
    end

    def group_recordings_for(root_recording)
      cached_group_recordings_by_key(root_recording).fetch(category_group_key, [])
    end

    def validate!
      raise ArgumentError, "attribute_name is required" if attribute_name.blank?
      raise ArgumentError, "category_group_key is required" if category_group_key.blank?
      return if SELECTIONS.include?(selection)

      raise ArgumentError, "selection must be one of: #{SELECTIONS.join(', ')}"
    end

    def sort_item_recordings(item_recordings)
      item_recordings.sort_by do |item_recording|
        [
          item_recording.recordable.position || 0,
          item_recording.recordable.name.to_s.downcase
        ]
      end
    end

    def category_item_recordings_for(group_recording)
      return [] unless group_recording

      cache = item_recordings_cache_for(group_recording)
      cache.fetch(group_recording.id) do
        cache[group_recording.id] = group_recording
          .child_recordings
          .of_type(RecordingStudioCategorisable::CategoryItem)
          .includes(:recordable)
          .to_a
      end
    end

    def cached_group_recordings_by_key(root_recording)
      return {} if root_recording.blank?

      if root_recording.instance_variable_defined?(GROUP_RECORDINGS_CACHE_IVAR)
        return root_recording.instance_variable_get(GROUP_RECORDINGS_CACHE_IVAR)
      end

      grouped_recordings = root_recording
        .recordings_query(include_children: true, type: RecordingStudioCategorisable::CategoryGroup)
        .includes(:recordable)
        .group_by { |recording| recording.recordable.key.to_s }

      root_recording.instance_variable_set(GROUP_RECORDINGS_CACHE_IVAR, grouped_recordings)
    end

    def item_recordings_cache_for(group_recording)
      if group_recording.instance_variable_defined?(ITEM_RECORDINGS_CACHE_IVAR)
        group_recording.instance_variable_get(ITEM_RECORDINGS_CACHE_IVAR)
      else
        group_recording.instance_variable_set(ITEM_RECORDINGS_CACHE_IVAR, {})
      end
    end
  end
  # rubocop:enable Metrics/ClassLength
end
