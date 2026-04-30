# frozen_string_literal: true

require_relative "hooks"

module RecordingStudioCategorisable
  class Configuration
    attr_reader :hooks
    attr_accessor :api_key, :timeout, :enable_feature_x, :root_recording_resolver

    def initialize
      @hooks = Hooks.new
      @root_recording_resolver = nil
    end

    def to_h
      {
        hooks_registered: hooks.instance_variable_get(:@registry).transform_values(&:size),
        root_recording_resolver: !root_recording_resolver.nil?
      }
    end

    def merge!(hash)
      return unless hash.respond_to?(:each)

      hash.each do |k, v|
        key = k.to_s
        setter = "#{key}="
        public_send(setter, v) if respond_to?(setter)
      end
    end
  end
end
