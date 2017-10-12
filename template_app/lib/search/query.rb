require 'yaml'

require_relative 'hit'

module Bookbinder
  module Search
    class Query
      attr_reader :search_term, :product_name, :product_version, :page_number, :result_list, :result_count, :last_page, :page_window

      def initialize(params)
        @search_term = params.fetch('q', '')
        @product_name = params.fetch('product_name', nil)
        @product_version = @product_name && params.fetch('product_version', nil)
        @page_number = @search_term == '' ? 1 : [params['page'].to_i, 1].max
      end

      def query_options
        options = YAML.load_file(File.expand_path('../../../search.yml', __FILE__))

        options['from'] = (page_number - 1) * 10
        options['query']['bool']['must']['simple_query_string']['query'] = search_term

        unless product_name.nil?
          filters = [{
            'term' => { 'product_name' => product_name }
          }]

          unless product_version.nil?
            filters << {'term' => { 'product_version' => product_version }}
          end

          options['query']['bool']['filter'] = {
            'bool' => {
              'must' => filters
            }
          }
        end

        options
      end

      def get_results(elasticsearch_client)
        if search_term == ''
          @result_count = 0
          @result_list = []
          @last_page = 1
        else
          results = elasticsearch_client.search index: 'searching', body: query_options
          @result_count = results['hits']['total']
          @result_list = results['hits']['hits'].map { |h| Hit.new(h) }
          @last_page = (result_count / 10.0).ceil
        end
        @page_window = calculate_page_window
      end

      private

      def calculate_page_window
        window_start = [page_number - 2, 1].max
        window_end = [window_start + 4, last_page].min
        window = (window_start .. window_end).to_a

        if window.length < 5 && window.last == last_page && window.first != 1
          window.unshift(window.first - 1)
          if window.length < 5
            window.unshift(window.first - 1)
          end
        end

        window
      end
    end
  end
end
