class BriefsController < ApplicationController
  REQUIRED_CATEGORY_REFERENCES = {
    status_category_item_recording_id: "page-status"
  }.freeze

  before_action :set_brief_recording, only: %i[edit update]

  def index
    @brief_recordings = brief_recordings_scope.includes(:recordable)
  end

  def new
    @brief = Brief.new
    load_category_fields
  end

  def create
    ensure_required_category_references!
    reject_unexpected_category_attributes!
    category_assignments = sanitized_category_assignments

    current_root_recording.record(Brief) do |brief|
      brief.assign_attributes(brief_params)
      apply_category_assignments(brief, category_assignments)
    end

    redirect_to root_path, notice: "Brief created."
  rescue ActiveRecord::RecordInvalid => error
    @brief = error.record
    load_category_fields
    render :new, status: :unprocessable_entity
  rescue RecordingStudioCategorisable::InvalidCategorySelectionError => error
    @brief = Brief.new(brief_params)
    @brief.errors.add(:base, "One or more category selections were invalid: #{error.message}")
    load_category_fields
    render :new, status: :unprocessable_entity
  end

  def edit
    @brief = @brief_recording.recordable
    load_category_fields
  end

  def update
    ensure_required_category_references!
    reject_unexpected_category_attributes!
    category_assignments = sanitized_category_assignments

    current_root_recording.revise(@brief_recording) do |brief|
      brief.assign_attributes(brief_params)
      apply_category_assignments(brief, category_assignments)
    end

    redirect_to root_path, notice: "Brief updated."
  rescue ActiveRecord::RecordInvalid => error
    @brief = error.record
    load_category_fields
    render :edit, status: :unprocessable_entity
  rescue RecordingStudioCategorisable::InvalidCategorySelectionError => error
    @brief = @brief_recording.recordable.dup
    @brief.assign_attributes(brief_params)
    @brief.errors.add(:base, "One or more category selections were invalid: #{error.message}")
    load_category_fields
    render :edit, status: :unprocessable_entity
  end

  private

  def set_brief_recording
    @brief_recording = brief_recordings_scope.includes(:recordable).find(params[:id])
  end

  def brief_recordings_scope
    current_root_recording
      .child_recordings
      .where(recordable_type: "Brief")
      .order(updated_at: :desc)
  end

  def brief_params
    params.require(:brief).permit(:title, :body)
  end

  def registration
    RecordingStudioCategorisable.configuration.registration_for(Brief)
  end

  def load_category_fields
    @category_fields = category_field_states(@brief)
  end

  def category_fields
    @category_fields_definitions ||= Array(registration&.fields)
  end

  def category_field_states(recordable)
    @category_field_states ||= category_fields.map do |field|
      {
        field: field,
        item_recordings: field.available_item_recordings(root_recording: current_root_recording, recordable: recordable)
      }
    end
  end

  def sanitized_category_assignments
    category_fields.each_with_object({}) do |field, assignments|
      assignments[field.key] = field.sanitize(
        params.dig(:brief, field.attribute_name),
        root_recording: current_root_recording,
        recordable: @brief
      )
    end
  end

  def apply_category_assignments(brief, assignments)
    category_fields.each do |field|
      field.write(brief, assignments.fetch(field.key))
    end
  end

  def ensure_required_category_references!
    RecordingStudioCategorisable::CategoryAssignmentGuard.ensure_required_references!(
      fields: category_fields,
      required_references: REQUIRED_CATEGORY_REFERENCES
    )
  end

  def reject_unexpected_category_attributes!
    RecordingStudioCategorisable::CategoryAssignmentGuard.reject_unexpected_attributes!(
      submitted_params: raw_brief_params,
      fields: category_fields
    )
  end

  def raw_brief_params
    params.fetch(:brief, ActionController::Parameters.new)
  end
end
