# frozen_string_literal: true

require "test_helper"

class RecordingStudioCategorisableTest < Minitest::Test
  def test_version
    assert_equal "0.1.0", RecordingStudioCategorisable::VERSION
  end

  def test_category_capability_is_registered
    registration = RecordingStudio.registered_capabilities[:categorisable]

    assert_equal "RecordingStudio::Capabilities::Categorisable", registration[:source]
    assert_includes Array(registration[:child_recordables]), "RecordingStudioCategorisable::Assignment"
  end
end
