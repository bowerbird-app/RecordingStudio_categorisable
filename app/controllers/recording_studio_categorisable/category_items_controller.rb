# frozen_string_literal: true

module RecordingStudioCategorisable
  class CategoryItemsController < ApplicationController
    before_action :set_category_group_recording
    before_action :set_category_item_recording, only: %i[show edit update destroy]

    def show
      ensure_authorized!(@category_item_recording, role: :view)
    end

    def new
      @category_item = CategoryItem.new
    end

    def create
      return unless ensure_authorized!(@category_group_recording, role: :admin)

      @category_item = CategoryItem.new(category_item_params)
      if @category_item.invalid?
        render :new, status: :unprocessable_entity
        return
      end

      created_recording = create_child_recording!(
        parent_recording: @category_group_recording,
        recordable: @category_item
      )
      redirect_to category_group_category_item_path(@category_group_recording, created_recording),
                  notice: "Category item created successfully."
    rescue ActiveRecord::RecordInvalid
      render :new, status: :unprocessable_entity
    end

    def edit
      return unless ensure_authorized!(@category_item_recording, role: :admin)

      @category_item = @category_item_recording.recordable
    end

    def update
      return unless ensure_authorized!(@category_item_recording, role: :admin)

      @category_item = prepare_recordable(recording: @category_item_recording, attributes: category_item_params)
      if @category_item.invalid?
        render :edit, status: :unprocessable_entity
        return
      end

      revised_recording = revise_recording!(recording: @category_item_recording, attributes: category_item_params)

      redirect_to category_group_category_item_path(@category_group_recording, revised_recording),
                  notice: "Category item updated successfully."
    rescue ActiveRecord::RecordInvalid
      @category_item ||= @category_item_recording.recordable
      render :edit, status: :unprocessable_entity
    end

    def destroy
      return unless ensure_authorized!(@category_item_recording, role: :admin)

      trash_recording!(recording: @category_item_recording)
      redirect_to category_group_path(@category_group_recording), notice: "Category item deleted successfully."
    end

    private

    def set_category_group_recording
      @category_group_recording = active_recording_scope.find_by!(
        id: params[:category_group_id],
        recordable_type: CategoryGroup.name
      )
    end

    def set_category_item_recording
      @category_item_recording = find_child_recording!(
        parent_recording: @category_group_recording,
        id: params[:id],
        recordable_type: CategoryItem.name
      )
    end

    def category_item_params
      params.require(:category_item).permit(:label, :description, :color, :position, metadata: {})
    end
  end
end
