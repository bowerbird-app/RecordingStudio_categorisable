# frozen_string_literal: true

module RecordingStudioCategorisable
  class CategoryItemsController < ApplicationController
    before_action :set_category_group_recording
    before_action :set_category_item_recording, only: %i[edit update destroy]
    before_action :set_usage_report, only: %i[edit destroy]

    def new
      @category_item = CategoryItem.new
    end

    def create
      ensure_category_item_create_allowed!

      current_root_recording.record(CategoryItem,
                                    parent_recording: @category_group_recording) do |item|
        assign_category_item_attributes(item)
      end

      redirect_to category_group_path(@category_group_recording), notice: "Category item created."
    rescue ActiveRecord::RecordInvalid => e
      @category_item = e.record
      render :new, status: :unprocessable_entity
    end

    def edit
      @category_item = @category_item_recording.recordable
      @item_usage_count = @usage_report.item_usage_count(@category_item_recording)
      @editable_fields = editable_fields_for(@category_group_recording)
    end

    def update
      ensure_category_item_update_allowed!

      current_root_recording.revise(@category_item_recording) do |item|
        assign_category_item_attributes(item)
      end

      redirect_to category_group_path(@category_group_recording), notice: "Category item updated."
    rescue ActiveRecord::RecordInvalid => e
      @category_item = e.record
      @item_usage_count = UsageReport.new.item_usage_count(@category_item_recording)
      @editable_fields = editable_fields_for(@category_group_recording)
      render :edit, status: :unprocessable_entity
    end

    def destroy
      ensure_category_item_delete_allowed!

      usage_count = @usage_report.item_usage_count(@category_item_recording)
      if usage_count.positive?
        redirect_to category_group_path(@category_group_recording),
                    alert: destroy_blocked_message("Category item", usage_count)
        return
      end

      destroy_recording(@category_item_recording)
      redirect_to category_group_path(@category_group_recording), notice: "Category item deleted."
    end

    private

    def assign_category_item_attributes(item)
      item.assign_attributes(category_item_params)
      item.key = item.key.parameterize if item.key.present?
    end

    def category_item_params
      params.require(:category_item).permit(:name, :key, :description)
    end

    def set_category_group_recording
      @category_group_recording = active_recordings_scope(
        current_root_recording.recordings_query(include_children: true, type: CategoryGroup)
      ).includes(:recordable).find(params[:category_group_id])
    end

    def set_category_item_recording
      @category_item_recording = active_recordings_scope(
        @category_group_recording.child_recordings.of_type(CategoryItem)
      ).includes(:recordable).find(params[:id])
    end

    def set_usage_report
      @usage_report = UsageReport.new
    end

    def category_item_capability
      RecordingStudioCategorisable.configuration.category_item_capability_for(
        @category_group_recording.recordable.key,
        root_recordable_type: current_root_recording.recordable_type
      )
    end

    def ensure_category_item_create_allowed!
      return unless category_item_capability
      return if category_item_capability.dig(:allow, :create)

      raise unauthorized_category_item_change_error(:create)
    end

    def ensure_category_item_update_allowed!
      capability = category_item_capability
      return unless capability

      current_item = @category_item_recording.recordable
      requested_item = current_item.dup
      requested_item.assign_attributes(category_item_params)

      disallowed_changes = []
      disallowed_changes << :name if requested_item.name != current_item.name && !capability.dig(:allow, :update_name)
      disallowed_changes << :description if requested_item.description != current_item.description && !capability.dig(
        :allow, :update_description
      )
      disallowed_changes << :key if requested_item.key != current_item.key && !capability.dig(:allow, :update_key)

      return if disallowed_changes.empty?

      raise unauthorized_category_item_change_error(disallowed_changes)
    end

    def ensure_category_item_delete_allowed!
      return unless category_item_capability
      return if category_item_capability.dig(:allow, :delete)

      raise unauthorized_category_item_change_error(:delete)
    end

    def unauthorized_category_item_change_error(disallowed_changes)
      UnauthorizedError.new(
        "Category item changes are not allowed for: #{Array(disallowed_changes).map(&:to_s).join(', ')}"
      )
    end

    def destroy_blocked_message(label, usage_count)
      suffix = usage_count == 1 ? "" : "s"

      "#{label} cannot be deleted while #{usage_count} assignment#{suffix} still use it."
    end

    def destroy_recording(recording)
      recording.update!(trashed_at: Time.current)
    end

    def editable_fields_for(category_group_recording)
      capability = RecordingStudioCategorisable.configuration.category_item_capability_for(
        category_group_recording.recordable.key,
        root_recordable_type: current_root_recording.recordable_type
      )

      return { name: true, description: true } if capability.blank?

      {
        name: capability.dig(:allow, :update_name),
        description: capability.dig(:allow, :update_description)
      }
    end
  end
end
