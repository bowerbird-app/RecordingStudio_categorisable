# frozen_string_literal: true

module RecordingStudioCategorisable
  class CategoryGroupsController < ApplicationController
    before_action :set_category_group_recording, only: %i[show edit update destroy]
    before_action :set_usage_report, only: %i[index show destroy]

    def index
      recordings = current_root_recording
                   .recordings_query(include_children: true, type: CategoryGroup)
                   .includes(:recordable, :parent_recording)

      @category_group_recordings = recordings
                                   .to_a
                                   .select { |recording| recording.recordable.present? }
                                   .group_by(&:recordable_id)
                                   .values
                                   .map { |versions| versions.max_by(&:created_at) }
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
      parent_recording = selected_parent_recording(default_parent: current_root_recording)
      category_group_recording = create_category_group_recording(parent_recording)

      redirect_to category_group_path(category_group_recording), notice: "Category group created."
    rescue ActiveRecord::RecordInvalid => error
      @category_group = error.record
      render :new, status: :unprocessable_entity
    end

    def edit
      @category_group = @category_group_recording.recordable
    end

    def update
      parent_recording = selected_parent_recording(default_parent: @category_group_recording.parent_recording)
      validate_parent_recording!(parent_recording)

      @category_group_recording.class.transaction do
        current_root_recording.revise(@category_group_recording) do |group|
          assign_category_group_attributes(group, exclude_recording_id: @category_group_recording.id)
        end

        @category_group_recording.update!(parent_recording: parent_recording)
      end

      redirect_to category_group_path(@category_group_recording), notice: "Category group updated."
    rescue ActiveRecord::RecordInvalid => error
      @category_group = error.record
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
      group.key = group.key.parameterize if group.key.present?
      validate_unique_key!(group, exclude_recording_id: exclude_recording_id)
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
      params.require(:category_group).permit(:name, :key, :description)
    end

    def selected_parent_recording(default_parent: current_root_recording)
      category_group_params = params.fetch(:category_group, {})
      return default_parent unless category_group_params.key?(:parent_recording_id)

      requested_parent_id = category_group_params[:parent_recording_id].presence
      return current_root_recording if requested_parent_id.blank?

      current_root_recording
        .recordings_query(include_children: true)
        .includes(:parent_recording)
        .find(requested_parent_id)
    end

    def validate_parent_recording!(parent_recording)
      return unless invalid_parent_recording?(parent_recording)

      category_group = @category_group_recording.recordable.dup
      category_group.assign_attributes(category_group_params)
      category_group.errors.add(
        :base,
        "Category groups cannot be moved under themselves or their descendants"
      )
      raise ActiveRecord::RecordInvalid, category_group
    end

    def invalid_parent_recording?(parent_recording)
      current_recording = parent_recording

      while current_recording.present?
        return true if current_recording.id == @category_group_recording.id

        current_recording = current_recording.parent_recording
      end

      false
    end

    def set_category_group_recording
      @category_group_recording = load_recording(CategoryGroup)
    end

    def set_usage_report
      @usage_report = UsageReport.new
    end

    def validate_unique_key!(group, exclude_recording_id: nil)
      duplicate_group = current_root_recording
                        .recordings_query(include_children: true, type: CategoryGroup)
                        .includes(:recordable)
                        .find do |recording|
        recording.id != exclude_recording_id && recording.recordable.key == group.key
      end

      return unless duplicate_group

      group.errors.add(:key, "has already been taken within this root")
      raise ActiveRecord::RecordInvalid, group
    end

    def destroy_blocked_message(label, usage_count)
      suffix = usage_count == 1 ? "" : "s"

      "#{label} cannot be deleted while #{usage_count} assignment#{suffix} still use it."
    end
  end
end
