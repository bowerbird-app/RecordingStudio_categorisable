# frozen_string_literal: true

module RecordingStudioCategorisable
  class CategoryAssignmentsController < ApplicationController
    before_action :set_target_recording
    before_action :set_category_assignment_recording, only: [:destroy]

    def index
      return unless ensure_authorized!(@target_recording, role: :view)

      @category_assignment_recordings =
        @target_recording.child_recordings
                         .where(recordable_type: CategoryAssignment.name, trashed_at: nil)
                         .includes(:recordable)
    end

    def new
      return unless ensure_authorized!(@target_recording, role: :admin)

      @category_assignment = CategoryAssignment.new
      @available_category_items = available_category_items
    end

    def create
      return unless ensure_authorized!(@target_recording, role: :admin)

      @category_assignment = CategoryAssignment.new(category_assignment_params)
      if @category_assignment.invalid?
        @available_category_items = available_category_items
        render :new, status: :unprocessable_entity
        return
      end

      @target_recording.record(
        @category_assignment,
        actor: current_recording_studio_actor,
        parent_recording: @target_recording
      )
      redirect_to target_recording_category_assignments_path(@target_recording),
                  notice: "Category assigned successfully."
    rescue ActiveRecord::RecordInvalid
      @available_category_items = available_category_items
      render :new, status: :unprocessable_entity
    end

    def destroy
      return unless ensure_authorized!(@target_recording, role: :admin)

      (@category_assignment_recording.root_recording || @category_assignment_recording).trash(
        @category_assignment_recording,
        actor: current_recording_studio_actor
      )
      redirect_to target_recording_category_assignments_path(@target_recording),
                  notice: "Category assignment removed successfully."
    end

    private

    def set_target_recording
      @target_recording = RecordingStudio::Recording.find(params[:target_recording_id])
    end

    def set_category_assignment_recording
      @category_assignment_recording = RecordingStudio::Recording.find(params[:id])
    end

    def category_assignment_params
      params.require(:category_assignment).permit(:category_item_recording_id, metadata: {})
    end

    def available_category_items
      RecordingStudio::Recording.where(recordable_type: CategoryItem.name, trashed_at: nil)
                                .includes(:recordable)
                                .sort_by do |recording|
        [recording.recordable&.category_group&.label.to_s.downcase, recording.recordable&.label.to_s.downcase]
      end
    end
  end
end
