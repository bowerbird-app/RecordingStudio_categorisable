# frozen_string_literal: true

require "test_helper"

class RecordingRelationsTest < Minitest::Test
  def test_active_uses_trashable_scope_when_available
    relation = Object.new
    relation.define_singleton_method(:recording_studio_trashable_active) { :active_scope }

    assert_equal :active_scope, RecordingStudioCategorisable::RecordingRelations.active(relation)
  end

  def test_active_falls_back_to_trashed_at_filter
    relation = Object.new
    relation.define_singleton_method(:where) do |attributes|
      attributes
    end

    assert_equal({ trashed_at: nil }, RecordingStudioCategorisable::RecordingRelations.active(relation))
  end

  def test_root_for_prefers_explicit_root_recording
    root = Object.new
    recording = Struct.new(:root_recording).new(root)

    assert_equal root, RecordingStudioCategorisable::RecordingRelations.root_for(recording)
  end

  def test_root_for_returns_recording_when_root_is_missing
    recording = Struct.new(:root_recording).new(nil)

    assert_equal recording, RecordingStudioCategorisable::RecordingRelations.root_for(recording)
  end
end
