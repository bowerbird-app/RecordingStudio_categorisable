# frozen_string_literal: true

module RecordingStudioCategorisable
  module RecordingVisibility
    module_function

    def active_scope(scope)
      return scope unless scope.respond_to?(:where)

      model = scope.klass if scope.respond_to?(:klass)
      return scope unless model&.column_names&.include?("trashed_at")

      scope.where(trashed_at: nil)
    end

    def active_recording?(recording)
      return false if recording.blank?
      return true unless recording.respond_to?(:trashed_at)

      recording.trashed_at.nil?
    end
  end
end