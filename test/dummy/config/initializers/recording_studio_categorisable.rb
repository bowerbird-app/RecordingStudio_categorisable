# frozen_string_literal: true

RecordingStudioCategorisable.configure do |config|
  config.root_recording_resolver = lambda do |controller|
    ::ApplicationController.instance_method(:current_root_recording).bind_call(controller)
  end
end

RecordingStudioCategorisable.category_definitions = [
  {
    group_key: "page-status",
    group_name: "Page Status",
    group_description: "Single-select lifecycle state for pages.",
    items: [
      { key: "draft", name: "Draft" },
      { key: "published", name: "Published" }
    ]
  },
  {
    group_key: "page-topics",
    group_name: "Page Topics",
    group_description: "Multi-select taxonomy for page content.",
    items: [
      { key: "product", name: "Product" },
      { key: "studio", name: "Studio" },
      { key: "launch", name: "Launch" }
    ]
  },
  {
    group_key: "color",
    group_name: "Color",
    group_description: "Single-select color for pages.",
    items: [
      { key: "red", name: "Red" },
      { key: "green", name: "Green" },
      { key: "blue", name: "Blue" }
    ]
  }
]