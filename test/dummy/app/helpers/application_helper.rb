module ApplicationHelper
	def render_categorisable_input(category_key:, as: :select)
		context = categorisable_input_context_for(category_key)
		return missing_categorisable_input_message(category_key) unless context

		case as.to_sym
		when :select
			render_categorisable_select(context)
		when :radio
			render_categorisable_radio_fallback(context)
		else
			raise ArgumentError, "Unsupported input type: #{as.inspect}. Use :select or :radio."
		end
	end

	private

	def categorisable_input_context_for(category_key)
		root_recording = current_root_recording
		return unless root_recording

		preferred_class = current_categorisable_recordable_class
		candidate_classes = [preferred_class, Brief, Page].compact.uniq

		candidate_classes.filter_map do |recordable_class|
			registration = RecordingStudioCategorisable.configuration.registration_for(recordable_class)
			next unless registration

			field = registration.fields.find { |candidate| candidate.category_group_key.to_s == category_key.to_s }
			next unless field

			sample_recordable = current_categorisable_recordable_for(recordable_class) ||
													root_recording.recordings_query(type: recordable_class)
																			.includes(:recordable)
																			.first
																			&.recordable ||
													recordable_class.new

			{
				name: "#{recordable_class.model_name.param_key}[#{field.attribute_name}]",
				field: field,
				recordable: sample_recordable,
				item_recordings: field.available_item_recordings(root_recording: root_recording, recordable: sample_recordable)
			}
		end.first
	end

	def current_categorisable_recordable_class
		current_categorisable_recordable&.class
	end

	def current_categorisable_recordable
		@page || @brief || @sample_page || @sample_brief
	end

	def current_categorisable_recordable_for(recordable_class)
		recordable = current_categorisable_recordable
		return unless recordable
		return recordable if recordable.is_a?(recordable_class)

		nil
	end

	def render_categorisable_select(context)
		field = context[:field]
		recordable = context[:recordable]

		render FlatPack::Select::Component.new(
			name: context[:name],
			label: field.label,
			options: context[:item_recordings].map { |item_recording| [item_recording.recordable.name, item_recording.id] },
			value: field.multiple? ? Array(field.read(recordable)) : field.read(recordable),
			placeholder: "Select #{field.label.to_s.downcase}",
			searchable: true,
			multiple: field.multiple?
		)
	end

	def render_categorisable_radio_fallback(context)
		field = context[:field]
		return radio_requires_single_select_message if field.selection.to_s != "single"

		current_value = field.read(context[:recordable]).to_s

		content_tag(:div, class: "grid gap-2") do
			safe_join(context[:item_recordings].map { |item_recording|
				category_item = item_recording.recordable
				safe_join([
					tag.input(
						type: "radio",
						name: context[:name],
						value: item_recording.id,
						checked: current_value == item_recording.id.to_s,
						class: "mr-2"
					),
					content_tag(:span, category_item.name)
				])
			}.map { |radio_row| content_tag(:label, radio_row, class: "inline-flex items-center") })
		end
	end

	def missing_categorisable_input_message(category_key)
		content_tag(
			:p,
			"No category field is configured for key '#{category_key}'.",
			class: "text-sm text-(--surface-muted-content-color)"
		)
	end

	def radio_requires_single_select_message
		content_tag(
			:p,
			"Radio input is only available for single-select category fields.",
			class: "text-sm text-(--surface-muted-content-color)"
		)
	end
end
