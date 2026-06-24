class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  layout :application_layout

  before_action :authenticate_user!
  before_action :set_current_actor
  before_action :configure_categorisable_capabilities_for_current_root

  helper_method :current_workspace,
                :current_root_recording,
                :available_root_recordings,
                :available_root_recording_options,
                :current_root_recording_label,
                :workspace_root_selected?

  private

  def application_layout
    devise_controller? ? "application" : "flat_pack_sidebar"
  end

  def set_current_actor
    Current.actor = current_user
  end

  def current_workspace
    @current_workspace ||= begin
      selected_root = current_root_recording
      if selected_root&.recordable_type == "Workspace"
        selected_root.recordable
      else
        default_workspace
      end
    end
  end

  def current_root_recording
    @current_root_recording ||= begin
      selected_id = session[:current_root_recording_id].presence
      selected_root = available_root_recordings.find { |recording| recording.id.to_s == selected_id.to_s }

      selected_root || default_workspace_root_recording || available_root_recordings.first
    end
  end

  def available_root_recordings
    @available_root_recordings ||= begin
      RecordingStudio::Recording.unscoped
        .where(parent_recording_id: nil)
        .includes(:recordable)
        .select { |recording| switchable_root_recording?(recording) && recording.recordable.present? }
        .sort_by { |recording| [root_sort_weight(recording), root_label(recording).downcase] }
    end
  end

  def current_root_recording_label
    root = current_root_recording
    return "No root" if root.blank?

    root_label(root)
  end

  def available_root_recording_options
    available_root_recordings.map { |recording| [root_label(recording), recording.id] }
  end

  def workspace_root_selected?
    current_root_recording&.recordable_type == "Workspace"
  end

  def authorize_recording_studio_categorisable!
    return false unless current_user.present?
    return true unless defined?(RecordingStudioAccessible)

    root_recording = current_root_recording
    return false if root_recording.blank?

    RecordingStudioAccessible.authorized?(
      actor: current_user,
      recording: root_recording,
      role: required_categorisable_role
    )
  end

  def required_categorisable_role
    return :edit unless params[:controller].to_s.start_with?("recording_studio_categorisable/")

    group_key = requested_category_group_key
    return configured_category_role_for(group_key) if group_key.present?

    minimum_configured_category_role_for_current_root
  end

  def requested_category_group_key
    group_recording_id = params[:category_group_id].presence

    if group_recording_id.blank? && params[:controller].to_s == "recording_studio_categorisable/category_groups"
      group_recording_id = params[:id].presence
    end

    return if group_recording_id.blank?

    group_recording = current_root_recording
                      .recordings_query(include_children: true, type: RecordingStudioCategorisable::CategoryGroup)
                      .includes(:recordable)
                      .find_by(id: group_recording_id)

    group_recording&.recordable&.key
  end

  def configured_category_role_for(group_key)
    capability = fetch_category_group_capability(
      group_key,
      root_recordable_type: current_root_recording.recordable_type
    )
    return :edit if capability.blank? || !capability_enabled_for_current_root?(group_key)

    capability.fetch(:access, :edit).to_sym
  end

  def minimum_configured_category_role_for_current_root
    roles = RecordingStudioCategorisable.configuration.expected_category_groups.keys.filter_map do |key|
      next unless capability_enabled_for_current_root?(key)

      capability = fetch_category_group_capability(
        key,
        root_recordable_type: current_root_recording.recordable_type
      )
      next if capability.blank?

      capability.fetch(:access, :edit).to_sym
    end

    return :edit if roles.empty?

    roles.min_by { |role| role_priority_for(role) }
  end

  def capability_enabled_for_current_root?(group_key)
    expected_group = RecordingStudioCategorisable.configuration.expected_category_groups[group_key.to_s]
    return false if expected_group.blank?

    allowed_root_types = Array(expected_group[:root_recordable_types]).map(&:to_s)
    return true if allowed_root_types.empty?

    allowed_root_types.include?(current_root_recording.recordable_type.to_s)
  end

  def visible_category_group_for_current_root?(group_key)
    capability_enabled_for_current_root?(group_key) && capability_registered_for_current_root?(group_key)
  end

  def capability_registered_for_current_root?(group_key)
    fetch_category_group_capability(
      group_key,
      root_recordable_type: current_root_recording.recordable_type
    ).present? || fetch_category_item_capability(
      group_key,
      root_recordable_type: current_root_recording.recordable_type
    ).present?
  end

  def role_priority_for(role)
    {
      view: 0,
      edit: 1,
      admin: 2
    }.fetch(role.to_sym, 1)
  end

  def configure_categorisable_capabilities_for_current_root
    return unless defined?(RecordingStudioCategorisable)

    load_current_root_recordable_class_capabilities

    if admin_root_selected?
      apply_admin_reference_capabilities
    else
      apply_workspace_reference_capabilities
    end

    auto_seed_category_groups_for_current_root
  end

  def load_current_root_recordable_class_capabilities
    root_type = current_root_recording&.recordable_type
    return if root_type.blank?

    root_type.safe_constantize
  end

  def apply_workspace_reference_capabilities
    configure_reference_capabilities
  end

  def apply_admin_reference_capabilities
    configure_reference_capabilities
  end

  def configure_reference_capabilities
    return unless defined?(RecordingStudioCategorisable::Capabilities::Reference)

    page_class = "Page".safe_constantize
    brief_class = "Brief".safe_constantize

    return if page_class.blank? || brief_class.blank?

    RecordingStudioCategorisable::Capabilities::Reference.enabled(
      recordable: page_class,
      attribute_name: :status_category_item_recording_id,
      selection: :single,
      category_group_key: "page-status",
      label: "Status"
    )

    RecordingStudioCategorisable::Capabilities::Reference.enabled(
      recordable: page_class,
      attribute_name: :topic_category_item_recording_ids,
      selection: :multiple,
      category_group_key: "page-topics",
      label: "Topics"
    )

    RecordingStudioCategorisable::Capabilities::Reference.enabled(
      recordable: brief_class,
      attribute_name: :status_category_item_recording_id,
      selection: :single,
      category_group_key: "page-status",
      label: "Status"
    )
  end

  def apply_workspace_category_capabilities
    configure_group_and_item_capabilities do
      {
        mode: :workspace,
        group: {
          rename: true,
          reorder: false,
          move: true,
          update_description: true,
          update_key: false
        },
        item: {
          create: true,
          update_name: true,
          update_position: true,
          update_key: false,
          delete: true
        }
      }
    end
  end

  def apply_admin_category_capabilities
    configure_group_and_item_capabilities do
      {
        mode: :admin,
        group: {
          rename: true,
          reorder: false,
          move: true,
          update_description: true,
          update_key: true
        },
        item: {
          create: true,
          update_name: true,
          update_position: true,
          update_key: true,
          delete: true
        }
      }
    end
  end

  def configure_group_and_item_capabilities
    capability_sets = yield

    category_group_definitions.each do |definition|
      group_key = definition.fetch(:key).to_s

      # Only auto-register fallback capabilities for groups explicitly expected in this root.
      next unless capability_enabled_for_current_root?(group_key)

      next if capability_defined_for_current_root?(group_key)

      RecordingStudioCategorisable::Capabilities::CategoryGroup.enabled(
        key: group_key,
        name: definition.fetch(:name),
        root_recordable_type: current_root_recording&.recordable_type,
        allow: capability_sets.fetch(:group)
      )

      RecordingStudioCategorisable::Capabilities::CategoryItems.enabled(
        group_key: group_key,
        root_recordable_type: current_root_recording&.recordable_type,
        allow: capability_sets.fetch(:item)
      )
    end
  end

  def auto_seed_category_groups_for_current_root
    return if current_root_recording.blank?

    expected = RecordingStudioCategorisable.configuration.expected_category_groups
    return if expected.empty?

    root_recordable_type = current_root_recording.recordable_type.to_s
    configured_definitions = RecordingStudioCategorisable.category_definitions || []

    definitions = expected.values.filter_map do |group_def|
      allowed_root_types = Array(group_def[:root_recordable_types]).map(&:to_s)
      if allowed_root_types.any? && !allowed_root_types.include?(root_recordable_type)
        next
      end

      existing = current_root_recording
        .recordings_query(include_children: true, type: RecordingStudioCategorisable::CategoryGroup)
        .includes(:recordable)
        .find { |recording| recording.recordable&.key.to_s == group_def[:key] }
      next if existing

      configured = configured_definitions.find { |d| d[:key].to_s == group_def[:key] }

      {
        key: group_def[:key],
        name: group_def[:name],
        items: configured ? Array(configured[:items]) : []
      }
    end

    return if definitions.empty?

    RecordingStudioCategorisable::Services::SeedCategories.call(
      root_recording: current_root_recording,
      category_definitions: definitions
    )
  rescue StandardError
    # best-effort in dummy app
  end

  def capability_defined_for_current_root?(group_key)
    root_recordable_type = current_root_recording&.recordable_type.to_s
    return false if root_recordable_type.blank?

    configuration = RecordingStudioCategorisable.configuration
    normalized_group_key = group_key.to_s

    configuration.scoped_category_group_capabilities.dig(normalized_group_key, root_recordable_type).present? ||
      configuration.scoped_category_item_capabilities.dig(normalized_group_key, root_recordable_type).present?
  end

  def fetch_category_group_capability(group_key, root_recordable_type:)
    configuration = RecordingStudioCategorisable.configuration
    method = configuration.method(:category_group_capability_for)

    if supports_root_recordable_type_keyword?(method)
      configuration.category_group_capability_for(group_key, root_recordable_type: root_recordable_type)
    else
      configuration.category_group_capability_for(group_key)
    end
  end

  def fetch_category_item_capability(group_key, root_recordable_type:)
    configuration = RecordingStudioCategorisable.configuration
    method = configuration.method(:category_item_capability_for)

    if supports_root_recordable_type_keyword?(method)
      configuration.category_item_capability_for(group_key, root_recordable_type: root_recordable_type)
    else
      configuration.category_item_capability_for(group_key)
    end
  end

  def supports_root_recordable_type_keyword?(method)
    method.parameters.any? do |type, name|
      (type == :key || type == :keyreq) && name == :root_recordable_type
    end || method.parameters.any? { |type, _| type == :keyrest }
  end

  def category_group_definitions
    RecordingStudioCategorisable.category_definitions.presence || []
  end

  def admin_root_selected?
    current_root_recording&.recordable_type == "RecordingStudioAdmin::Admin"
  end

  def default_workspace
    @default_workspace ||= Workspace.first
  end

  def default_workspace_root_recording
    workspace = default_workspace
    return if workspace.blank?

    RecordingStudio::Recording.unscoped.find_by(recordable: workspace, parent_recording_id: nil)
  end

  def switchable_root_recording?(recording)
    return true if recording.recordable_type == "Workspace"

    recording.recordable_type == "RecordingStudioAdmin::Admin"
  end

  def root_sort_weight(recording)
    case recording.recordable_type
    when "Workspace"
      0
    when "RecordingStudioAdmin::Admin"
      1
    else
      2
    end
  end

  def root_label(recording)
    case recording.recordable_type
    when "Workspace"
      "Workspace: #{recording.recordable.name}"
    when "RecordingStudioAdmin::Admin"
      "Admin: #{recording.recordable.name}"
    else
      "#{recording.recordable_type.demodulize}: #{recording.recordable.respond_to?(:name) ? recording.recordable.name : recording.id}"
    end
  end
end
