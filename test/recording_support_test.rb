# frozen_string_literal: true

require "test_helper"

class RecordingSupportTest < Minitest::Test
  class FakeController
    include RecordingStudioCategorisable::RecordingSupport

    attr_reader :actor, :impersonator

    def initialize(actor: "actor", impersonator: "impersonator")
      @actor = actor
      @impersonator = impersonator
    end

    def current_recording_studio_actor
      actor
    end

    def current_recording_studio_impersonator
      impersonator
    end

    public :create_child_recording!,
           :prepare_recordable,
           :revise_recording!,
           :trash_recording!,
           :find_child_recording!,
           :root_recording_for
  end

  def setup
    @controller = FakeController.new
  end

  def test_create_child_recording_forwards_actor_and_parent
    parent_recording = Minitest::Mock.new
    recordable = Object.new

    parent_recording.expect(
      :record,
      :created,
      [recordable],
      actor: "actor",
      parent_recording: parent_recording
    )

    assert_equal(
      :created,
      @controller.create_child_recording!(parent_recording: parent_recording, recordable: recordable)
    )
    parent_recording.verify
  end

  def test_prepare_recordable_duplicates_and_assigns_attributes
    recordable = Struct.new(:attributes) do
      def dup
        self.class.new(attributes.dup)
      end

      def assign_attributes(new_attributes)
        self.attributes = attributes.merge(new_attributes)
      end
    end.new({ existing: "value" })

    recording = Struct.new(:recordable).new(recordable)
    prepared = @controller.prepare_recordable(recording: recording, attributes: { updated: true })

    assert_equal({ existing: "value", updated: true }, prepared.attributes)
    refute_same recordable, prepared
  end

  def test_revise_recording_forwards_attributes_to_root_recording
    revised = Object.new
    root = Minitest::Mock.new
    recording = Struct.new(:root_recording).new(root)

    root.expect(:revise, revised) do |recording_arg, options, &block|
      probe = Struct.new(:attributes) do
        def assign_attributes(new_attributes)
          self.attributes = new_attributes
        end
      end.new
      block.call(probe)
      recording_arg.equal?(recording) && options == { actor: "actor" } && probe.attributes == { label: "Updated" }
    end

    assert_equal revised, @controller.revise_recording!(recording: recording, attributes: { label: "Updated" })
    root.verify
  end

  def test_trash_recording_prefers_trashable_api_when_available
    recording = Object.new
    received = nil
    recording.define_singleton_method(:recording_studio_trashable_trash!) do |**kwargs|
      received = kwargs
      :trashed
    end

    assert_equal :trashed, @controller.trash_recording!(recording: recording, metadata: { reason: "cleanup" })
    assert_equal({ actor: "actor", impersonator: "impersonator", metadata: { reason: "cleanup" } }, received)
  end

  def test_trash_recording_falls_back_to_root_trash
    root = Minitest::Mock.new
    recording = Struct.new(:root_recording).new(root)

    root.expect(:trash, :trashed, [recording], actor: "actor")

    assert_equal :trashed, @controller.trash_recording!(recording: recording)
    root.verify
  end

  def test_find_child_recording_uses_active_scope_and_type_filter
    active_relation = Minitest::Mock.new
    active_relation.expect(:find_by!, :found, [], id: "123", recordable_type: "ExampleType")

    child_relation = Object.new
    child_relation.define_singleton_method(:recording_studio_trashable_active) { active_relation }

    parent_recording = Struct.new(:child_recordings).new(child_relation)

    assert_equal :found,
                 @controller.find_child_recording!(
                   parent_recording: parent_recording,
                   id: "123",
                   recordable_type: "ExampleType"
                 )
    active_relation.verify
  end
end
