# frozen_string_literal: true

module RecordingStudioCategorisable
  module CategoryAssignmentGuard
    module_function

    def ensure_required_references!(fields:, required_references:)
      missing_references = required_references.filter_map do |attribute_name, expected_group_key|
        field = fields.find { |candidate| candidate.attribute_name == attribute_name.to_sym }
        next if field && field.category_group_key.to_s == expected_group_key.to_s

        "#{attribute_name}=>#{expected_group_key}"
      end

      return if missing_references.empty?

      raise InvalidCategorySelectionError,
            "missing required category reference configuration: #{missing_references.join(', ')}"
    end

    def reject_unexpected_attributes!(submitted_params:, fields:, key_fragment: "category_item_recording")
      submitted_category_keys = submitted_params
                               .keys
                               .select { |key| key.to_s.include?(key_fragment) }
                               .map(&:to_s)
      allowed_category_keys = fields.map { |field| field.attribute_name.to_s }
      unexpected_keys = submitted_category_keys - allowed_category_keys

      return if unexpected_keys.empty?

      raise InvalidCategorySelectionError,
            "contains unexpected category attributes: #{unexpected_keys.join(', ')}"
    end
  end
end