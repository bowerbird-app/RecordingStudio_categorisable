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

      create_child_recording!(parent_recording: @target_recording, recordable: @category_assignment)
      redirect_to target_recording_category_assignments_path(@target_recording),
                  notice: "Category assigned successfully."
    rescue ActiveRecord::RecordInvalid
      @available_category_items = available_category_items
      render :new, status: :unprocessable_entity
    end

    def destroy
      return unless ensure_authorized!(@target_recording, role: :admin)

      trash_recording!(recording: @category_assignment_recording)
      redirect_to target_recording_category_assignments_path(@target_recording),
                  notice: "Category assignment removed successfully."
    end

    private

    def set_target_recording
      @target_recording = active_recording_scope.find(params[:target_recording_id])
    end

    def set_category_assignment_recording
      @category_assignment_recording = find_child_recording!(
        parent_recording: @target_recording,
        id: params[:id],
        recordable_type: CategoryAssignment.name
      )
    end

    def category_assignment_params
      params.require(:category_assignment).permit(:category_item_recording_id, metadata: {})
    end

    def available_category_items
      root_recording = root_recording_for(@target_recording)

      active_recording_scope
        .where(root_recording_id: root_recording&.id, recordable_type: CategoryItem.name)
        .includes(:recordable)
        .sort_by do |recording|
          [
            recording.recordable&.category_group&.label.to_s.downcase,
            recording.recordable&.label.to_s.downcase
          ]
        end
    end
  end
end
