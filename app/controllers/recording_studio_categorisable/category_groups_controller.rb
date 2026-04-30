# frozen_string_literal: true

module RecordingStudioCategorisable
  class CategoryGroupsController < ApplicationController
    before_action :set_parent_recording
    before_action :set_category_group_recording, only: [:show, :edit, :update, :destroy]

    def index
      @category_group_recordings = RecordingStudio::Recording.where(
        recordable_type: "RecordingStudioCategorisable::CategoryGroup"
      ).includes(:recordable).order("recordables.label ASC")
    end

    def show
      authorize_action!(@category_group_recording)
      @category_items = @category_group_recording.children.where(
        recordable_type: "RecordingStudioCategorisable::CategoryItem"
      ).includes(:recordable).order("recordables.label ASC")
    end

    def new
      @category_group = CategoryGroup.new
    end

    def create
      result = @parent_recording.record(CategoryGroup) do |recordable|
        recordable.label = category_group_params[:label]
      end

      if result.success?
        redirect_to category_group_path(result.recording), notice: "Category group created successfully."
      else
        @category_group = CategoryGroup.new(category_group_params)
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize_action!(@category_group_recording)
      @category_group = @category_group_recording.recordable
    end

    def update
      authorize_action!(@category_group_recording)
      
      if @category_group_recording.recordable.update(category_group_params)
        redirect_to category_group_path(@category_group_recording), notice: "Category group updated successfully."
      else
        @category_group = @category_group_recording.recordable
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize_action!(@category_group_recording)
      @category_group_recording.trash!
      redirect_to category_groups_path, notice: "Category group deleted successfully."
    end

    private

    def set_parent_recording
      @parent_recording = current_workspace_recording
    end

    def set_category_group_recording
      @category_group_recording = RecordingStudio::Recording.find(params[:id])
    end

    def category_group_params
      params.require(:category_group).permit(:label)
    end
  end
end
