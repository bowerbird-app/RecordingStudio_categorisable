# frozen_string_literal: true

module RecordingStudioCategorisable
  class CategoryItemsController < ApplicationController
    before_action :set_category_group_recording
    before_action :set_category_item_recording, only: [:show, :edit, :update, :destroy]

    def index
      @category_item_recordings = @category_group_recording.children.where(
        recordable_type: "RecordingStudioCategorisable::CategoryItem"
      ).includes(:recordable).order("recordables.label ASC")
    end

    def show
      authorize_action!(@category_item_recording)
    end

    def new
      @category_item = CategoryItem.new
    end

    def create
      result = @category_group_recording.record(CategoryItem) do |recordable|
        recordable.label = category_item_params[:label]
      end

      if result.success?
        redirect_to category_group_category_item_path(@category_group_recording, result.recording), 
                    notice: "Category item created successfully."
      else
        @category_item = CategoryItem.new(category_item_params)
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize_action!(@category_item_recording)
      @category_item = @category_item_recording.recordable
    end

    def update
      authorize_action!(@category_item_recording)
      
      if @category_item_recording.recordable.update(category_item_params)
        redirect_to category_group_category_item_path(@category_group_recording, @category_item_recording), 
                    notice: "Category item updated successfully."
      else
        @category_item = @category_item_recording.recordable
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize_action!(@category_item_recording)
      @category_item_recording.trash!
      redirect_to category_group_category_items_path(@category_group_recording), 
                  notice: "Category item deleted successfully."
    end

    private

    def set_category_group_recording
      @category_group_recording = RecordingStudio::Recording.find(params[:category_group_id])
    end

    def set_category_item_recording
      @category_item_recording = RecordingStudio::Recording.find(params[:id])
    end

    def category_item_params
      params.require(:category_item).permit(:label)
    end
  end
end
