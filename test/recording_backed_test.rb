# frozen_string_literal: true

require "test_helper"

class RecordingBackedTest < Minitest::Test
  ExampleRecord = Class.new do
    include RecordingStudioCategorisable::RecordingBacked

    attr_reader :id

    def initialize(id)
      @id = id
    end

    def self.name = "ExampleRecord"
  end

  def test_recording_looks_up_wrapper_by_type_and_id
    recording_class = Class.new do
      class << self
        attr_accessor :received
      end

      def self.find_by(attributes)
        self.received = attributes
        :wrapper
      end
    end

    with_recording_const(recording_class) do
      assert_equal :wrapper, ExampleRecord.new("abc-123").recording
    end

    assert_equal({ recordable_type: "ExampleRecord", recordable_id: "abc-123" }, recording_class.received)
  end

  private

  def with_recording_const(recording_class)
    parent_defined = Object.const_defined?(:RecordingStudio)
    parent = parent_defined ? Object.const_get(:RecordingStudio) : Object.const_set(:RecordingStudio, Module.new)
    original_defined = parent.const_defined?(:Recording, false)
    original = parent.const_get(:Recording) if original_defined
    parent.send(:remove_const, :Recording) if original_defined
    parent.const_set(:Recording, recording_class)
    yield
  ensure
    parent.send(:remove_const, :Recording) if parent.const_defined?(:Recording, false)
    parent.const_set(:Recording, original) if original_defined
    Object.send(:remove_const, :RecordingStudio) unless parent_defined
  end
end
