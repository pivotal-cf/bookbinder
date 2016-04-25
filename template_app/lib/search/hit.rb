module Bookbinder
  module Search
    class Hit
      def initialize(attrs = {})
        source_fields = attrs.fetch('_source')
        @title = source_fields.fetch('title').sub(/\A(.+)\|.*\z/, '\\1').strip
        @url = source_fields.fetch('url')

        @text = attrs.fetch('highlight').fetch('text').first.strip
      end

      attr_reader :title, :url, :text
    end
  end
end
