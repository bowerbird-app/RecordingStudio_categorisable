# frozen_string_literal: true

module RecordingStudioCategorisable
  class HomeController < ApplicationController
    def index
      redirect_to category_groups_path
    end
  end
end
