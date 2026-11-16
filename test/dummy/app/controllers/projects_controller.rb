# frozen_string_literal: true

class ProjectsController < ApplicationController
  def index
    @projects = RecordingStudio::Recording.kept.where(recordable_type: "Project").includes(:recordable)
  end

  def show
    @recording = RecordingStudio::Recording.kept.find(params[:id])
  end
end
