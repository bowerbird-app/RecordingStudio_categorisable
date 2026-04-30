# frozen_string_literal: true

module RecordingStudioCategorisable
  class CategoryItemsController < ApplicationController
    before_action :set_category_group_recording
    before_action :set_category_item_recording, only: %i[show edit update destroy]

    def show
      return unless authorize_action!(@category_item_recording, role: :view)
    end

    def new
      @category_item = CategoryItem.new
    end

    def create
      return unless authorize_action!(@category_group_recording, role: :admin)

      @category_item = CategoryItem.new(category_item_params)
      if @category_item.invalid?
        render :new, status: :unprocessable_entity
        return
      end

      created_recording = @category_group_recording.record(
        @category_item,
        actor: current_recording_studio_actor,
        parent_recording: @category_group_recording
      )
      redirect_to category_group_category_item_path(@category_group_recording, created_recording),
                  notice: "Category item created successfully."
    rescue ActiveRecord::RecordInvalid
      render :new, status: :unprocessable_entity
    end

    def edit
      return unless authorize_action!(@category_item_recording, role: :admin)

      @category_item = @category_item_recording.recordable
    end

    def update
      return unless authorize_action!(@category_item_recording, role: :admin)

      @category_item = @category_item_recording.recordable.dup
      @category_item.assign_attributes(category_item_params)
      if @category_item.invalid?
        render :edit, status: :unprocessable_entity
        return
      end

      revised_recording = (@category_item_recording.root_recording || @category_item_recording).revise(
        @category_item_recording,
        actor: current_recording_studio_actor
      ) do |recordable|
        recordable.assign_attributes(category_item_params)
      end

      redirect_to category_group_category_item_path(@category_group_recording, revised_recording),
                  notice: "Category item updated successfully."
    rescue ActiveRecord::RecordInvalid
      @category_item ||= @category_item_recording.recordable
      render :edit, status: :unprocessable_entity
    end

    def destroy
      return unless authorize_action!(@category_item_recording, role: :admin)

      (@category_item_recording.root_recording || @category_item_recording).trash(
        @category_item_recording,
        actor: current_recording_studio_actor
      )
      redirect_to category_group_path(@category_group_recording), notice: "Category item deleted successfully."
    end

    private

    def set_category_group_recording
      @category_group_recording = RecordingStudio::Recording.find(params[:category_group_id])
    end

    def set_category_item_recording
      @category_item_recording = RecordingStudio::Recording.find(params[:id])
    end

    def category_item_params
      params.require(:category_item).permit(:label, :description, :color, :position, metadata: {})
    end
  end
end
