# frozen_string_literal: true

module RecordingStudioCategorisable
  class CategoryGroupsController < ApplicationController
    before_action :set_category_group_recording, only: %i[show edit update destroy]
    before_action :set_usage_report, only: %i[index show destroy]

    def index
      @category_group_recordings = current_root_recording
                                   .recordings_query(include_children: true, type: CategoryGroup)
                                   .includes(:recordable, :parent_recording)
    end

    def show
      @category_item_recordings = @category_group_recording
                                  .child_recordings
                                  .of_type(CategoryItem)
                                  .includes(:recordable)
                                  .sort_by do |recording|
        [recording.recordable.position || 0,
         recording.recordable.name.to_s.downcase]
      end
      @group_usage_count = @usage_report.group_usage_count(@category_group_recording)
    end

    def new
      @category_group = CategoryGroup.new
    end

    def create
      parent_recording = selected_parent_recording
      category_group_recording = create_category_group_recording(parent_recording)

      redirect_to category_group_path(category_group_recording), notice: "Category group created."
    rescue ActiveRecord::RecordInvalid
      @category_group = CategoryGroup.new(category_group_params)
      render :new, status: :unprocessable_entity
    end

    def edit
      @category_group = @category_group_recording.recordable
    end

    def update
      current_root_recording.revise(@category_group_recording) do |group|
        assign_category_group_attributes(group, exclude_recording_id: @category_group_recording.id)
      end

      @category_group_recording.update!(parent_recording: selected_parent_recording)
      redirect_to category_group_path(@category_group_recording), notice: "Category group updated."
    rescue ActiveRecord::RecordInvalid
      @category_group = @category_group_recording.recordable.dup
      @category_group.assign_attributes(category_group_params)
      render :edit, status: :unprocessable_entity
    end

    def destroy
      usage_count = @usage_report.group_usage_count(@category_group_recording)
      if usage_count.positive?
        redirect_to category_group_path(@category_group_recording),
                    alert: destroy_blocked_message("Category group", usage_count)
        return
      end

      current_root_recording.hard_delete(@category_group_recording, include_children: true)
      redirect_to category_groups_path, notice: "Category group deleted."
    end

    private

    def assign_category_group_attributes(group, exclude_recording_id: nil)
      group.assign_attributes(category_group_params)
      group.slug = group.slug.parameterize if group.slug.present?
      validate_unique_slug!(group, exclude_recording_id: exclude_recording_id)
    end

    def create_category_group_recording(parent_recording)
      current_root_recording.record(
        CategoryGroup,
        parent_recording: parent_recording
      ) do |group|
        assign_category_group_attributes(group)
      end
    end

    def category_group_params
      params.require(:category_group).permit(:name, :slug, :description)
    end

    def selected_parent_recording
      requested_parent_id = params.dig(:category_group, :parent_recording_id).presence
      return current_root_recording if requested_parent_id.blank?

      current_root_recording
        .recordings_query(include_children: true)
        .find(requested_parent_id)
    end

    def set_category_group_recording
      @category_group_recording = load_recording(CategoryGroup)
    end

    def set_usage_report
      @usage_report = UsageReport.new
    end

    def validate_unique_slug!(group, exclude_recording_id: nil)
      duplicate_group = current_root_recording
                        .recordings_query(include_children: true, type: CategoryGroup)
                        .includes(:recordable)
                        .find do |recording|
        recording.id != exclude_recording_id && recording.recordable.slug == group.slug
      end

      return unless duplicate_group

      group.errors.add(:slug, "has already been taken within this root")
      raise ActiveRecord::RecordInvalid, group
    end

    def destroy_blocked_message(label, usage_count)
      suffix = usage_count == 1 ? "" : "s"

      "#{label} cannot be deleted while #{usage_count} assignment#{suffix} still use it."
    end
  end
end
