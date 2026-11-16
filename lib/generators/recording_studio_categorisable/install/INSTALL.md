Categories are mounted. Next:

1. Set `category_holder_types` in `config/initializers/recording_studio_categorisable.rb` to the root types that should hold categories.
2. Enable the capability on each type that can be filed:

```ruby
include RecordingStudio::Capabilities::Categorisable.to
```

3. Generate and run the host migrations listed in the README.
4. Rebuild Tailwind with `bin/rails tailwindcss:build`.
