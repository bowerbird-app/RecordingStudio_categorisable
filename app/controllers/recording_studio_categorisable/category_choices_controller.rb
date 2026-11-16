# frozen_string_literal: true

module RecordingStudioCategorisable
  class CategoryChoicesController < ApplicationController
    before_action :load_recording

    def edit
      @options = helpers.recording_studio_category_options(@recording.root_recording_or_self)
      @category_recording = @recording.category_recording
    end

    def update
      category = RecordingStudio::Recording.kept.find(params.fetch(:category_recording_id))
      @recording.assign_category!(category, actor: current_actor)
      redirect_to edit_recording_category_path(@recording), notice: "Category saved."
    rescue RecordingStudioCategorisable::NotAllowed
      deny_access
    rescue ArgumentError, ActiveRecord::RecordInvalid => e
      redirect_to edit_recording_category_path(@recording), alert: e.message
    end

    def destroy
      @recording.remove_category!(actor: current_actor)
      redirect_to edit_recording_category_path(@recording), notice: "Category removed."
    rescue RecordingStudioCategorisable::NotAllowed
      deny_access
    end

    private

    def load_recording
      @recording = RecordingStudio::Recording.kept.find(params[:recording_id])
      return if Access.allowed?(actor: current_actor, recording: @recording, role: :edit)

      deny_access
    end
  end
end
