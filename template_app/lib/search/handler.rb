require 'elasticsearch'

require_relative 'query'
require_relative 'renderer'

module Bookbinder
  module Search
    class Handler
      def initialize
        @renderer = Renderer.new
      end

      def call(request_env)
        results = query.search(extract_query_params(request_env['QUERY_STRING']))

        [200, {'Content-Type' => 'text/html'}, [renderer.render_results(results)]]
      rescue Exception => e
        puts e.message
        puts e.backtrace.join("\n")

        [500, {'Content-Type' => 'text/plain'}, ['An error occurred']]
      end

      def extract_query_params(param_string)
        params = (param_string || '').split('&').map do |param|
          param.split('=')
        end
        Hash[params]
      end

      private

      attr_reader :renderer

      def elasticsearch_url
        @elasticsearch_url ||= JSON.parse(ENV['VCAP_SERVICES'])['searchly'][0]['credentials']['uri']
      end

      def query
        Query.new(Elasticsearch::Client.new(url: elasticsearch_url))
      end
    end
  end
end
