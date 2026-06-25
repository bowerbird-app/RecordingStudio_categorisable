# frozen_string_literal: true

# This migration comes from recording_studio_orderable (originally 20260514000002)
class RenameRecordingStudioRecordingOrdersToRecordingStudioRecordingStudioOrders < ActiveRecord::Migration[8.1]
  def change
    rename_table :recording_studio_recording_orders, :recording_studio_recording_studio_orders
  end
end
