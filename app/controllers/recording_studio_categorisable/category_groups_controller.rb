# frozen_string_literal: true

module RecordingStudioCategorisable
  class CategoryGroupsController < ApplicationController
    before_action :set_category_group_recording, only: %i[show edit update destroy]
    before_action :set_usage_report, only: %i[index show destroy]

    def index
      recordings = active_recordings_scope(
        current_root_recording.recordings_query(include_children: true, type: CategoryGroup)
      ).includes(:recordable, :parent_recording)

      @category_group_recordings = recordings
                                   .to_a
                                   .select { |recording| recording.recordable.present? }
                                   .group_by { |recording| recording.recordable.key }
                                   .values
                                   .map { |versions| versions.max_by(&:created_at) }
                                   .select { |recording| visible_for_current_root?(recording.recordable.key) }

      @editable_group_keys = @category_group_recordings
                             .select { |recording| editable_from_capability?(recording.recordable.key) }
                             .map { |recording| recording.recordable.key }
                             .uniq

      @item_counts_by_group_id = visible_item_counts_for(@category_group_recordings)
    end

    def show
      @category_item_recordings = active_recordings_scope(
        @category_group_recording.child_recordings.of_type(CategoryItem)
      ).includes(:recordable)
                                  .sort_by do |recording|
        [recording.recordable.position || 0,
         recording.recordable.name.to_s.downcase]
      end
      @category_item_capability = category_item_capability_for(@category_group_recording.recordable.key)
      @can_edit_group = editable_from_capability?(@category_group_recording.recordable.key)
      @can_create_items = item_create_allowed?(@category_item_capability)
      @can_edit_items = item_update_allowed?(@category_item_capability)
      @can_delete_items = item_delete_allowed?(@category_item_capability)
    end

    def new
      @category_group = CategoryGroup.new
    end

    def create
      parent_recording = selected_parent_recording(default_parent: current_root_recording)
      category_group_recording = create_category_group_recording(parent_recording)

      redirect_to category_group_path(category_group_recording), notice: "Category group created."
    rescue ActiveRecord::RecordInvalid => e
      @category_group = e.record
      render :new, status: :unprocessable_entity
    end

    def edit
      @category_group = @category_group_recording.recordable
      @editable_fields = editable_fields_for(@category_group_recording)
    end

    def update
      capability = category_group_capability_for(@category_group_recording.recordable.key)
      parent_recording = selected_parent_recording(default_parent: @category_group_recording.parent_recording)
      validate_parent_recording!(parent_recording)
      ensure_group_update_allowed!(parent_recording)

      @category_group_recording.class.transaction do
        group = @category_group_recording.recordable
        original_key = group.key
        assign_category_group_attributes(
          group,
          exclude_recording_id: @category_group_recording.id,
          validate_unique_key: false,
          allowed_attributes: allowed_update_attributes(capability)
        )

        group.errors.add(:name, :blank) if group.name.blank?
        group.errors.add(:key, :blank) if group.key.blank?
        raise ActiveRecord::RecordInvalid, group if group.errors.any?

        validate_unique_key!(group, exclude_recording_id: @category_group_recording.id) if group.key != original_key

        @category_group_recording.recordable.class.where(id: group.id).update_all(
          name: group.name,
          key: group.key,
          description: group.description,
          updated_at: Time.current
        )

        @category_group_recording.update!(parent_recording: parent_recording)
      end

      redirect_to category_group_path(@category_group_recording), notice: "Category group updated."
    rescue ActiveRecord::RecordInvalid => e
      @category_group = e.record
      @editable_fields = editable_fields_for(@category_group_recording)
      render :edit, status: :unprocessable_entity
    end

    def destroy
      usage_count = @usage_report.group_usage_count(@category_group_recording)
      if usage_count.positive?
        redirect_to category_group_path(@category_group_recording),
                    alert: destroy_blocked_message("Category group", usage_count)
        return
      end

      destroy_recording_tree(@category_group_recording)
      redirect_to category_groups_path, notice: "Category group deleted."
    end

    private

    def assign_category_group_attributes(group, exclude_recording_id: nil, validate_unique_key: true,
                                         allowed_attributes: %i[name key description])
      group.assign_attributes(category_group_params(allowed_attributes: allowed_attributes))
      group.key = group.key.parameterize if group.key.present?
      validate_unique_key!(group, exclude_recording_id: exclude_recording_id) if validate_unique_key
    end

    def create_category_group_recording(parent_recording)
      current_root_recording.record(
        CategoryGroup,
        parent_recording: parent_recording
      ) do |group|
        assign_category_group_attributes(group)
      end
    end

    def category_group_params(allowed_attributes: %i[name key description])
      params.require(:category_group).permit(*allowed_attributes)
    end

    def raw_category_group_params
      params.fetch(:category_group, ActionController::Parameters.new)
    end

    def selected_parent_recording(default_parent: current_root_recording)
      group_params = raw_category_group_params
      return default_parent unless group_params.key?(:parent_recording_id)

      requested_parent_id = group_params[:parent_recording_id].presence
      return current_root_recording if requested_parent_id.blank?

      active_recordings_scope(
        current_root_recording.recordings_query(include_children: true)
      )
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
                        .then { |scope| active_recordings_scope(scope) }
                        .includes(:recordable)
                        .find do |recording|
        recording.id != exclude_recording_id && recording.recordable.key == group.key
      end

      return unless duplicate_group

      group.errors.add(:key, "has already been taken within this root")
      raise ActiveRecord::RecordInvalid, group
    end

    def ensure_group_update_allowed!(parent_recording)
      capability = category_group_capability_for(@category_group_recording.recordable.key)
      return unless capability

      current_group = @category_group_recording.recordable
      requested_group = current_group.dup
      requested_group.assign_attributes(category_group_params)

      disallowed_changes = []
      disallowed_changes << :name if requested_group.name != current_group.name && !capability.dig(:allow, :rename)
      disallowed_changes << :description if requested_group.description != current_group.description && !capability.dig(
        :allow, :update_description
      )
      disallowed_changes << :key if requested_group.key != current_group.key
      disallowed_changes << :parent_recording_id if parent_recording.id != @category_group_recording.parent_recording_id && !capability.dig(
        :allow, :move
      )

      return if disallowed_changes.empty?

      raise unauthorized_category_group_change_error(disallowed_changes)
    end

    def unauthorized_category_group_change_error(disallowed_changes)
      UnauthorizedError.new(
        "Category group changes are not allowed for: #{disallowed_changes.map(&:to_s).join(', ')}"
      )
    end

    def category_group_capability_for(key)
      RecordingStudioCategorisable.configuration.category_group_capability_for(
        key,
        root_recordable_type: current_root_recording.recordable_type
      )
    end

    def category_item_capability_for(group_key)
      RecordingStudioCategorisable.configuration.category_item_capability_for(
        group_key,
        root_recordable_type: current_root_recording.recordable_type
      )
    end

    def item_create_allowed?(capability)
      return true if capability.blank?

      capability.dig(:allow, :create)
    end

    def item_update_allowed?(capability)
      return true if capability.blank?

      allow = capability.fetch(:allow, {}).to_h
      allow[:update_name] || allow[:update_position] || allow[:update_key] || allow[:update_description]
    end

    def item_delete_allowed?(capability)
      return true if capability.blank?

      capability.dig(:allow, :delete)
    end

    def editable_fields_for(category_group_recording)
      capability = category_group_capability_for(category_group_recording.recordable.key)
      return { name: true, key: false, description: true, move: true } unless capability

      {
        name: capability.dig(:allow, :rename),
        key: false,
        description: capability.dig(:allow, :update_description),
        move: capability.dig(:allow, :move)
      }
    end

    def editable_from_capability?(group_key)
      capability = category_group_capability_for(group_key)
      return false if capability.blank?
      return false unless capability_enabled_for_current_root?(group_key)

      capability.fetch(:allow, {}).to_h.values.any?(&:present?)
    end

    def visible_for_current_root?(group_key)
      capability_enabled_for_current_root?(group_key) && capability_registered_for_current_root?(group_key)
    end

    def capability_registered_for_current_root?(group_key)
      category_group_capability_for(group_key).present? || category_item_capability_for(group_key).present?
    end

    def capability_enabled_for_current_root?(group_key)
      expected_group = RecordingStudioCategorisable.configuration.expected_category_groups[group_key.to_s]
      return false if expected_group.blank?

      allowed_root_types = Array(expected_group[:root_recordable_types]).map(&:to_s)
      return true if allowed_root_types.empty?

      allowed_root_types.include?(current_root_recording.recordable_type.to_s)
    end

    def allowed_update_attributes(capability)
      return %i[name description] unless capability

      [].tap do |allowed|
        allowed << :name if capability.dig(:allow, :rename)
        allowed << :description if capability.dig(:allow, :update_description)
      end
    end

    def destroy_blocked_message(label, usage_count)
      suffix = usage_count == 1 ? "" : "s"

      "#{label} cannot be deleted while #{usage_count} assignment#{suffix} still use it."
    end

    def destroy_recording_tree(recording)
      active_recordings_scope(recording.child_recordings).to_a.each do |child_recording|
        destroy_recording_tree(child_recording)
      end

      recording.update!(trashed_at: Time.current)
    end

    def visible_item_counts_for(group_recordings)
      group_ids = group_recordings.map(&:id)
      return {} if group_ids.empty?

      active_recordings_scope(
        RecordingStudio::Recording.where(
          parent_recording_id: group_ids,
          recordable_type: RecordingStudioCategorisable::CategoryItem.name
        )
      ).reorder(nil)
       .group(:parent_recording_id)
       .count
    end
  end
end
