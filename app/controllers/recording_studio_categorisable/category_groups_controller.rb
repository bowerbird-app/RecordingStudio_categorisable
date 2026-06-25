# frozen_string_literal: true

module RecordingStudioCategorisable
  class CategoryGroupsController < ApplicationController
    before_action :set_category_group_recording, only: %i[show edit update destroy reorder_items]
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
      @category_item_capability = category_item_capability_for(@category_group_recording.recordable.key)
      @category_item_recordings = category_item_recordings_for(@category_group_recording, @category_item_capability)
      orderable_enabled = RecordingStudioCategorisable::OrderableSupport.orderable_enabled?(@category_item_capability)
      @orderable_items = orderable_enabled && orderable_storage_available?
      @reorder_mode = @orderable_items && params[:reorder].to_s == "true"

      if orderable_enabled && !@orderable_items
        flash.now[:alert] = "Reordering is unavailable until recording_studio_orderable migrations are run."
      end

      @can_edit_group = editable_from_capability?(@category_group_recording.recordable.key)
      @can_create_items = item_create_allowed?(@category_item_capability)
      @can_edit_items = item_update_allowed?(@category_item_capability)
      @can_delete_items = item_delete_allowed?(@category_item_capability)
    end

    def reorder_items
      capability = category_item_capability_for(@category_group_recording.recordable.key)
      unless RecordingStudioCategorisable::OrderableSupport.orderable_enabled?(capability)
        raise UnauthorizedError, "Category item changes are not allowed for: orderable"
      end

      unless orderable_storage_available?
        render json: {
          ok: false,
          error: "Reordering is unavailable until recording_studio_orderable migrations are run."
        }, status: :unprocessable_entity
        return
      end

      ordered_recording_ids = Array(params[:ordered_recording_ids]).map(&:to_s)
      group_key = @category_group_recording.recordable.key
      order_group_key = RecordingStudioCategorisable::OrderableSupport.order_group_key_for(group_key)

      RecordingStudioCategorisable::OrderableSupport.ensure_category_group_ordering!(group_key)
      order_record = @category_group_recording.find_or_create_recording_order!(
        order_group_key,
        actor: Current.actor,
        owner: nil
      )
      order_record.reorder!(ordered_recording_ids: ordered_recording_ids, actor: Current.actor)

      render json: { ok: true }
    rescue UnauthorizedError => e
      render json: { ok: false, error: e.message }, status: :forbidden
    rescue StandardError => e
      render json: { ok: false, error: e.message }, status: :unprocessable_entity
    end

    def new
      @category_group = CategoryGroup.new
    end

    def create
      category_group_recording = create_category_group_recording

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
      ensure_group_update_allowed!

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

    def create_category_group_recording
      current_root_recording.record(
        CategoryGroup,
        parent_recording: current_root_recording
      ) do |group|
        assign_category_group_attributes(group)
      end
    end

    def category_group_params(allowed_attributes: %i[name key description])
      params.require(:category_group).permit(*allowed_attributes)
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

    def ensure_group_update_allowed!
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
      allow[:update_name] || allow[:orderable] || allow[:update_key] || allow[:update_description]
    end

    def category_item_recordings_for(group_recording, capability)
      if RecordingStudioCategorisable::OrderableSupport.orderable_enabled?(capability) && orderable_storage_available?
        ordered_recordings = ordered_category_items_with_recovery(
          group_recording,
          group_recording.recordable.key
        )

        return ordered_recordings.select do |recording|
          recording.recordable.present? && recording.trashed_at.nil?
        end
      end

      active_recordings_scope(
        group_recording.child_recordings.of_type(CategoryItem)
      ).includes(:recordable)
        .sort_by { |recording| [recording.recordable.name.to_s.downcase, recording.recordable.key.to_s] }
    end

    def ordered_category_items_with_recovery(group_recording, group_key)
      retried = false

      begin
        RecordingStudioCategorisable::OrderableSupport.ordered_category_items_for(group_recording, group_key)
      rescue StandardError => e
        raise unless duplicate_order_error?(e) && !retried

        retried = true
        recover_duplicate_default_order_records!(group_recording, group_key)
        retry
      end
    end

    def duplicate_order_error?(error)
      error.class.name.to_s.end_with?("DuplicateOrderError")
    end

    def recover_duplicate_default_order_records!(group_recording, group_key)
      return unless defined?(::RecordingStudio::RecordingStudioOrder)

      order_group_key = RecordingStudioCategorisable::OrderableSupport.order_group_key_for(group_key)
      duplicates = ::RecordingStudio::RecordingStudioOrder
                   .where(
                     parent_recording_id: group_recording.id,
                     group_key: order_group_key,
                     owner_type: nil,
                     owner_id: nil
                   )
                   .where("COALESCE(BTRIM(name), '') = ''")
                   .order(updated_at: :desc, created_at: :desc, id: :desc)
                   .to_a

      return if duplicates.size <= 1

      keep_order = duplicates.shift
      drop_ids = duplicates.map(&:id)
      ::RecordingStudio::RecordingStudioOrder.where(id: drop_ids).delete_all

      Rails.logger.warn(
        "[RecordingStudioCategorisable] Removed #{drop_ids.size} duplicate order rows for " \
        "parent=#{group_recording.id} group_key=#{order_group_key}. Kept=#{keep_order.id}"
      )
    end

    def orderable_storage_available?
      ActiveRecord::Base.connection.data_source_exists?("recording_studio_recording_studio_orders")
    rescue StandardError
      false
    end

    def item_delete_allowed?(capability)
      return true if capability.blank?

      capability.dig(:allow, :delete)
    end

    def editable_fields_for(category_group_recording)
      capability = category_group_capability_for(category_group_recording.recordable.key)
      return { name: true, key: false, description: true } unless capability

      {
        name: capability.dig(:allow, :rename),
        key: false,
        description: capability.dig(:allow, :update_description)
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
