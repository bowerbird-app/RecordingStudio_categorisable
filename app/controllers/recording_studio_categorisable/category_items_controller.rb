# frozen_string_literal: true

module RecordingStudioCategorisable
  class CategoryItemsController < ApplicationController
    before_action :set_category_group_recording
    before_action :set_category_item_recording, only: %i[edit update destroy]
    before_action :set_usage_report, only: %i[edit destroy]

    def new
      @category_item = CategoryItem.new(position: next_position)
    end

    def create
      current_root_recording.record(CategoryItem,
                                    parent_recording: @category_group_recording) do |item|
        assign_category_item_attributes(item)
      end

      redirect_to category_group_path(@category_group_recording), notice: "Category item created."
    rescue ActiveRecord::RecordInvalid
      @category_item = CategoryItem.new(category_item_params)
      render :new, status: :unprocessable_entity
    end

    def edit
      @category_item = @category_item_recording.recordable
      @item_usage_count = @usage_report.item_usage_count(@category_item_recording)
    end

    def update
      current_root_recording.revise(@category_item_recording) do |item|
        assign_category_item_attributes(item)
      end

      redirect_to category_group_path(@category_group_recording), notice: "Category item updated."
    rescue ActiveRecord::RecordInvalid
      @category_item = @category_item_recording.recordable.dup
      @category_item.assign_attributes(category_item_params)
      @item_usage_count = UsageReport.new.item_usage_count(@category_item_recording)
      render :edit, status: :unprocessable_entity
    end

    def destroy
      usage_count = @usage_report.item_usage_count(@category_item_recording)
      if usage_count.positive?
        redirect_to category_group_path(@category_group_recording),
                    alert: destroy_blocked_message("Category item", usage_count)
        return
      end

      current_root_recording.hard_delete(@category_item_recording)
      redirect_to category_group_path(@category_group_recording), notice: "Category item deleted."
    end

    private

    def assign_category_item_attributes(item)
      item.assign_attributes(category_item_params)
      item.slug = item.slug.parameterize if item.slug.present?
    end

    def category_item_params
      params.require(:category_item).permit(:name, :slug, :description, :position)
    end

    def next_position
      @category_group_recording
        .child_recordings
        .of_type(CategoryItem)
        .includes(:recordable)
        .map { |recording| recording.recordable.position.to_i }
        .max
        .to_i + 1
    end

    def set_category_group_recording
      @category_group_recording = current_root_recording
                                  .recordings_query(include_children: true, type: CategoryGroup)
                                  .includes(:recordable)
                                  .find(params[:category_group_id])
    end

    def set_category_item_recording
      @category_item_recording = @category_group_recording
                                 .child_recordings
                                 .of_type(CategoryItem)
                                 .includes(:recordable)
                                 .find(params[:id])
    end

    def set_usage_report
      @usage_report = UsageReport.new
    end

    def destroy_blocked_message(label, usage_count)
      suffix = usage_count == 1 ? "" : "s"

      "#{label} cannot be deleted while #{usage_count} assignment#{suffix} still use it."
    end
  end
end
