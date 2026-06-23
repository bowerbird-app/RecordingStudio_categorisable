# frozen_string_literal: true

RecordingStudioCategorisable.category_definitions = [
  {
    key: "page-status",
    name: "Page Status",
    description: "Single-select lifecycle state for pages.",
    items: [
      { key: "draft", name: "Draft", position: 1 },
      { key: "published", name: "Published", position: 2 }
    ]
  },
  {
    key: "page-topics",
    name: "Page Topics",
    description: "Multi-select taxonomy for page content.",
    items: [
      { key: "product", name: "Product", position: 1 },
      { key: "studio", name: "Studio", position: 2 },
      { key: "launch", name: "Launch", position: 3 }
    ]
  }
]