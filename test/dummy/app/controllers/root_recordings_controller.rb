class RootRecordingsController < ApplicationController
  def switch
    selected_root = available_root_recordings.find do |recording|
      recording.id.to_s == params[:root_recording_id].to_s
    end

    if selected_root.present?
      session[:current_root_recording_id] = selected_root.id
    else
      session.delete(:current_root_recording_id)
    end

    redirect_back fallback_location: root_path
  end
end
