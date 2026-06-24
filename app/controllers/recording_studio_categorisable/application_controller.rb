# frozen_string_literal: true

module RecordingStudioCategorisable
  class ApplicationController < (defined?(::ApplicationController) ? ::ApplicationController : ActionController::Base)
    protect_from_forgery with: :exception
    layout "recording_studio_categorisable/application"
    before_action :authorize_recording_studio_categorisable_access!
    before_action :auto_seed_expected_category_groups
    rescue_from UnauthorizedError, with: :render_forbidden

    helper_method :current_root_recording, :parent_recording_options

    private

    def current_root_recording
      return super if defined?(super)

      root_recording = RecordingStudioCategorisable.configuration.resolve_root_recording(self)

      @current_root_recording ||= root_recording.tap do |resolved_root_recording|
        if resolved_root_recording.blank?
          raise MissingRootRecordingError,
                "A root recording resolver is required for RecordingStudioCategorisable"
        end
      end
    end

    def load_recording(recordable_type)
      active_recordings_scope(
        current_root_recording.recordings_query(include_children: true, type: recordable_type)
      )
        .includes(:recordable)
        .find(params[:id])
    end

    def authorize_recording_studio_categorisable_access!
      return super if defined?(super)

      if respond_to?(:authorize_recording_studio_categorisable!, true)
        return if authorize_recording_studio_categorisable!

        raise UnauthorizedError, "You are not authorized to manage categories"
      end

      RecordingStudioCategorisable.configuration.authorize!(self)
    end

    def parent_recording_options
      active_recordings_scope(
        current_root_recording.recordings_query(include_children: true)
      )
        .includes(:recordable)
        .map do |recording|
          [
            "#{recording.recordable_type.demodulize}: #{recording_label(recording)}",
            recording.id
          ]
        end
    end

    def recording_label(recording)
      recordable = recording.recordable
      return recordable.name if recordable.respond_to?(:name)
      return recordable.title if recordable.respond_to?(:title)

      recordable.class.model_name.human
    end

    def active_recordings_scope(scope)
      RecordingStudioCategorisable::RecordingVisibility.active_scope(scope)
    end

    def render_forbidden(exception)
      return if RecordingStudioCategorisable.configuration.handle_unauthorized(self, exception)

      respond_to do |format|
        format.html { render plain: exception.message, status: :forbidden }
        format.any { head :forbidden }
      end
    end

    def auto_seed_expected_category_groups
      expected = RecordingStudioCategorisable.configuration.expected_category_groups
      return if expected.empty?

      root = current_root_recording
      return if root.blank?

      root_recordable_type = root.recordable_type.to_s

      configured_definitions = RecordingStudioCategorisable.category_definitions || []

      definitions = expected.values.filter_map do |group_def|
        allowed_root_types = Array(group_def[:root_recordable_types]).map(&:to_s)
        next if allowed_root_types.any? && !allowed_root_types.include?(root_recordable_type)

        configured = configured_definitions.find { |d| d[:key].to_s == group_def[:key] }
        configured_items = configured ? Array(configured[:items]) : []
        supplemental_items = supplemental_items_for_group(
          group_key: group_def[:key].to_s,
          current_root: root,
          existing_item_keys: configured_items.map { |item| item[:key].to_s }
        )

        {
          key: group_def[:key],
          name: group_def[:name],
          items: configured_items + supplemental_items
        }
      end

      return if definitions.empty?

      RecordingStudioCategorisable::Services::SeedCategories.call(
        root_recording: root,
        category_definitions: definitions
      )
    rescue StandardError => _e
      # Auto-seeding is best-effort; never block the request
    end

    def supplemental_items_for_group(group_key:, current_root:, existing_item_keys:)
      known_keys = Array(existing_item_keys).map(&:to_s).uniq
      candidates_by_key = {}

      source_groups = RecordingStudioCategorisable::RecordingVisibility.active_scope(
        RecordingStudio::Recording.where(recordable_type: RecordingStudioCategorisable::CategoryGroup)
      ).includes(:recordable)
       .to_a
       .select do |recording|
        recording.root_recording_id != current_root.id && recording.recordable&.key.to_s == group_key
      end

      source_groups.each do |group_recording|
        item_recordings = RecordingStudioCategorisable::RecordingVisibility.active_scope(
          group_recording.child_recordings.of_type(RecordingStudioCategorisable::CategoryItem)
        ).includes(:recordable).to_a

        item_recordings.each do |item_recording|
          item = item_recording.recordable
          next if item.blank?

          key = item.key.to_s
          next if key.blank? || known_keys.include?(key)

          existing = candidates_by_key[key]
          if existing.blank? || item_recording.created_at > existing[:created_at]
            candidates_by_key[key] = {
              created_at: item_recording.created_at,
              item: {
                key: key,
                name: item.name,
                description: item.description,
                position: item.position
              }
            }
          end
        end
      end

      candidates_by_key.values
                       .sort_by { |entry| [entry[:item][:position] || 0, entry[:item][:name].to_s.downcase] }
                       .map { |entry| entry[:item] }
    end
  end
end
