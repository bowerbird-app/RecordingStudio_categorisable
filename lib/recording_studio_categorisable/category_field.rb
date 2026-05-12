# frozen_string_literal: true

module RecordingStudioCategorisable
  class CategoryField
    SELECTIONS = %i[single multiple].freeze

    attr_reader :attribute_name, :selection, :category_group_slug, :group_resolver

    def initialize(attribute_name:, selection:, category_group_slug:, **options)
      @attribute_name = attribute_name.to_sym
      @selection = selection.to_sym
      @category_group_slug = category_group_slug.to_s
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

      group_recordings = root_recording
        .recordings_query(include_children: true, type: RecordingStudioCategorisable::CategoryGroup)
        .includes(:recordable)
        .select { |recording| recording.recordable.slug == category_group_slug }

      raise AmbiguousCategoryGroupError, "multiple category groups share slug #{category_group_slug.inspect}" if group_recordings.many?

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

    def validate!
      raise ArgumentError, "attribute_name is required" if attribute_name.blank?
      raise ArgumentError, "category_group_slug is required" if category_group_slug.blank?
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

      group_recording
        .child_recordings
        .of_type(RecordingStudioCategorisable::CategoryItem)
        .includes(:recordable)
    end
  end
end
