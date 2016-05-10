require 'yaml'

require_relative 'result'

module Bookbinder
  module Search
    class Query
      def initialize(client)
        @client = client
      end

      def search(params)
        query = params.fetch('q', '')

        return Result.new(query, 0, [], 1) if query == ''

        page_number = [params['page'].to_i, 1].max

        query_options = YAML.load_file(File.expand_path('../../../search.yml', __FILE__))

        query_options['from'] = (page_number - 1) * 10
        query_options['query']['bool']['should']['query_string']['query'] = query

        results = client.search index: 'searching', body: query_options

        Result.new(
          query,
          results['hits']['total'],
          results['hits']['hits'],
          page_number
        )

      end

      private

      attr_reader :client

    end
  end
end
