# frozen_string_literal: true

module RecordingStudioCategorisable
  class CategoriesController < ApplicationController
    def index
      @roots = visible_root_recordings
      @categories = categories_under(@roots)
    end

    def new
      @roots = visible_root_recordings
      @parents = parent_options(@roots)
      @parent_recording_id = params[:parent_recording_id].presence || @parents.first&.last
    end

    def create
      parent = RecordingStudio::Recording.kept.find(params.fetch(:parent_recording_id))
      RecordingStudioCategorisable.record_category(
        parent_recording: parent, name: params.fetch(:name), actor: current_actor
      )
      redirect_to root_path, notice: "Category added."
    rescue RecordingStudioCategorisable::NotAllowed
      deny_access
    rescue ArgumentError, ActiveRecord::RecordInvalid, RecordingStudio::InvalidParent => e
      redirect_to new_category_path, alert: e.message
    end

    private

    def parent_options(roots)
      categories = categories_under(roots)
      holders = roots.map { |recording| [holder_label(recording), recording.id] }
      nested = categories.map { |recording| [category_label(recording), recording.id] }
      holders + nested
    end

    def category_label(recording)
      prefix = "– " * [recording.depth - 1, 0].max
      "#{prefix}#{recording.recordable.name}"
    end

    def holder_label(recording)
      RecordingStudio.recordable_name(recording.recordable)
    end
  end
end
