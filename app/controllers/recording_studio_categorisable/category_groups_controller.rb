# frozen_string_literal: true

module RecordingStudioCategorisable
  class CategoryGroupsController < ApplicationController
    before_action :set_parent_recording
    before_action :set_category_group_recording, only: %i[show edit update destroy]

    def index
      return unless ensure_authorized!(@parent_recording, role: :view)

      category_group_recordings = active_recordings(@parent_recording.child_recordings)
      @category_group_recordings = category_group_recordings
                                   .where(recordable_type: CategoryGroup.name)
                                   .includes(:recordable)
                                   .sort_by { |recording| recording.recordable&.label.to_s.downcase }
    end

    def show
      return unless ensure_authorized!(@category_group_recording, role: :view)

      category_items = active_recordings(@category_group_recording.child_recordings)
      @category_items = category_items
                        .where(recordable_type: CategoryItem.name)
                        .includes(:recordable)
                        .sort_by { |recording| recording.recordable&.label.to_s.downcase }
    end

    def new
      @category_group = CategoryGroup.new
    end

    def create
      return unless ensure_authorized!(@parent_recording, role: :admin)

      @category_group = CategoryGroup.new(category_group_params)
      if @category_group.invalid?
        render :new, status: :unprocessable_entity
        return
      end

      created_recording = create_child_recording!(parent_recording: @parent_recording, recordable: @category_group)
      redirect_to category_group_path(created_recording), notice: "Category group created successfully."
    rescue ActiveRecord::RecordInvalid
      render :new, status: :unprocessable_entity
    end

    def edit
      return unless ensure_authorized!(@category_group_recording, role: :admin)

      @category_group = @category_group_recording.recordable
    end

    def update
      return unless ensure_authorized!(@category_group_recording, role: :admin)

      @category_group = prepare_recordable(recording: @category_group_recording, attributes: category_group_params)
      if @category_group.invalid?
        render :edit, status: :unprocessable_entity
        return
      end

      revised_recording = revise_recording!(recording: @category_group_recording, attributes: category_group_params)

      redirect_to category_group_path(revised_recording), notice: "Category group updated successfully."
    rescue ActiveRecord::RecordInvalid
      @category_group ||= @category_group_recording.recordable
      render :edit, status: :unprocessable_entity
    end

    def destroy
      return unless ensure_authorized!(@category_group_recording, role: :admin)

      trash_recording!(recording: @category_group_recording)
      redirect_to category_groups_path, notice: "Category group deleted successfully."
    end

    private

    def set_parent_recording
      @parent_recording = current_root_recording
      return if @parent_recording

      redirect_to fallback_root_path, alert: "No root recording is available for categories."
    end

    def set_category_group_recording
      @category_group_recording = find_child_recording!(
        parent_recording: @parent_recording,
        id: params[:id],
        recordable_type: CategoryGroup.name
      )
    end

    def category_group_params
      params.require(:category_group).permit(:label, :description, :position, metadata: {})
    end
  end
end
