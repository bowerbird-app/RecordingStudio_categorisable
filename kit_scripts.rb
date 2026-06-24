# delete
group_ids = RecordingStudio::Recording.where(recordable_type: 'RecordingStudioCategorisable::CategoryGroup').pluck(:id)
item_ids = RecordingStudio::Recording.where(recordable_type: 'RecordingStudioCategorisable::CategoryItem').pluck(:id)
all_ids = (group_ids + item_ids).uniq

puts "CategoryGroup recordings: #{group_ids.size}"
puts "CategoryItem recordings: #{item_ids.size}"
puts "Total categorisable recordings: #{all_ids.size}"

if defined?(RecordingStudio::Event)
deleted_events = RecordingStudio::Event.where(recording_id: all_ids).delete_all
puts "Deleted events: #{deleted_events}"
end

deleted_recordings = RecordingStudio::Recording.where(id: all_ids).delete_all
deleted_groups = RecordingStudioCategorisable::CategoryGroup.delete_all
deleted_items = RecordingStudioCategorisable::CategoryItem.delete_all

puts "Deleted recording rows: #{deleted_recordings}"
puts "Deleted category groups: #{deleted_groups}"
puts "Deleted category items: #{deleted_items}"

# verifier
puts 'Groups: ' + RecordingStudioCategorisable::CategoryGroup.count.to_s
puts 'Items: ' + RecordingStudioCategorisable::CategoryItem.count.to_s
puts 'Group recordings: ' + RecordingStudio::Recording.where(recordable_type: 'RecordingStudioCategorisable::CategoryGroup').count.to_s
puts 'Item recordings: ' + RecordingStudio::Recording.where(recordable_type: 'RecordingStudioCategorisable::CategoryItem').count.to_s
