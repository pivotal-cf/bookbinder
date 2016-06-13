module Bookbinder
  module Search
    class Hit
      def initialize(attrs = {})
        source_fields = attrs.fetch('_source')
        @title = source_fields.fetch('title').sub(/\A(.+)\|.*\z/, '\\1').strip
        @url = source_fields.fetch('url')
        @product_name = source_fields['product_name']
        @product_version = source_fields['product_version']

        if attrs.has_key?('highlight')
          @text = attrs.fetch('highlight').fetch('text').first.strip
        else
          @text = source_fields.fetch('summary')
        end
      end

      attr_reader :title, :url, :text, :product_name, :product_version
    end
  end
end
