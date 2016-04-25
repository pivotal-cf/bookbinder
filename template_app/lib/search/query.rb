require 'yaml'

require_relative 'result'

module Bookbinder
  module Search
    class Query
      def initialize(client)
        @client = client
      end

      def search(params)
        return Result.new(params['q'], 0, [], 1) if params['q'].nil?

        page_number = (params['page'] || 1).to_i

        query_options = YAML.load_file(File.expand_path('../../../search.yml', __FILE__))

        query_options['from'] = (page_number - 1) * 10
        query_options['query']['query_string']['query'] = params['q']

        results = client.search index: 'searching', body: query_options

        Result.new(
          params['q'],
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
