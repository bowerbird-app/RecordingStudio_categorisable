class PagesController < ApplicationController
  before_action :set_page_recording, only: %i[edit update]

  def index
    @page_recordings = current_root_recording.recordings_query(type: Page).includes(:recordable)
  end

  def new
    @page = Page.new
    load_category_fields
  end

  def create
    category_assignments = sanitized_category_assignments

    current_root_recording.record(Page) do |page|
      page.assign_attributes(page_params)
      apply_category_assignments(page, category_assignments)
    end

    redirect_to root_path, notice: "Page created."
  rescue ActiveRecord::RecordInvalid => error
    @page = error.record
    load_category_fields
    render :new, status: :unprocessable_entity
  rescue RecordingStudioCategorisable::InvalidCategorySelectionError => error
    @page = Page.new(page_params)
    @page.errors.add(:base, "One or more category selections were invalid: #{error.message}")
    load_category_fields
    render :new, status: :unprocessable_entity
  end

  def edit
    @page = @page_recording.recordable
    load_category_fields
  end

  def update
    category_assignments = sanitized_category_assignments

    current_root_recording.revise(@page_recording) do |page|
      page.assign_attributes(page_params)
      apply_category_assignments(page, category_assignments)
    end

    redirect_to root_path, notice: "Page updated."
  rescue ActiveRecord::RecordInvalid => error
    @page = error.record
    load_category_fields
    render :edit, status: :unprocessable_entity
  rescue RecordingStudioCategorisable::InvalidCategorySelectionError => error
    @page = @page_recording.recordable.dup
    @page.assign_attributes(page_params)
    @page.errors.add(:base, "One or more category selections were invalid: #{error.message}")
    load_category_fields
    render :edit, status: :unprocessable_entity
  end

  private

  def set_page_recording
    @page_recording = current_root_recording.recordings_query(type: Page).includes(:recordable).find(params[:id])
  end

  def page_params
    params.require(:page).permit(:title, :body)
  end

  def registration
    RecordingStudioCategorisable.configuration.registration_for(Page)
  end

  def load_category_fields
    @category_fields = registration.fields.map do |field|
      {
        field: field,
        item_recordings: field.available_item_recordings(root_recording: current_root_recording, recordable: @page)
      }
    end
  end

  def sanitized_category_assignments
    registration.fields.each_with_object({}) do |field, assignments|
      assignments[field.key] = field.sanitize(
        params.dig(:page, field.attribute_name),
        root_recording: current_root_recording,
        recordable: @page
      )
    end
  end

  def apply_category_assignments(page, assignments)
    registration.fields.each do |field|
      field.write(page, assignments.fetch(field.key))
    end
  end
end
