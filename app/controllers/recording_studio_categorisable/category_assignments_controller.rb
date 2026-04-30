# frozen_string_literal: true

module RecordingStudioCategorisable
  class CategoryAssignmentsController < ApplicationController
    before_action :set_target_recording
    before_action :set_category_assignment_recording, only: [:destroy]

    def index
      @category_assignment_recordings = @target_recording.children.where(
        recordable_type: "RecordingStudioCategorisable::CategoryAssignment"
      ).includes(:recordable)
    end

    def new
      @category_assignment = CategoryAssignment.new
      @available_category_items = RecordingStudio::Recording.where(
        recordable_type: "RecordingStudioCategorisable::CategoryItem"
      ).includes(:recordable).order("recordables.label ASC")
    end

    def create
      category_item_recording = RecordingStudio::Recording.find(
        category_assignment_params[:category_item_recording_id]
      )

      result = @target_recording.record(CategoryAssignment) do |recordable|
        recordable.category_item_recording = category_item_recording
      end

      if result.success?
        redirect_to target_category_assignments_path, notice: "Category assigned successfully."
      else
        @category_assignment = CategoryAssignment.new
        @available_category_items = RecordingStudio::Recording.where(
          recordable_type: "RecordingStudioCategorisable::CategoryItem"
        ).includes(:recordable).order("recordables.label ASC")
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      authorize_action!(@category_assignment_recording)
      @category_assignment_recording.trash!
      redirect_to target_category_assignments_path, notice: "Category assignment removed successfully."
    end

    private

    def set_target_recording
      @target_recording = RecordingStudio::Recording.find(params[:target_recording_id])
    end

    def set_category_assignment_recording
      @category_assignment_recording = RecordingStudio::Recording.find(params[:id])
    end

    def category_assignment_params
      params.require(:category_assignment).permit(:category_item_recording_id)
    end

    def target_category_assignments_path
      # This would be dynamically constructed based on the target recordable type
      # For now, return a generic path
      recording_studio_categorisable.root_path
    end
  end
end
