require 'elasticsearch'
require 'cgi'
require 'json'

require_relative 'query'
require_relative 'renderer'

module Bookbinder
  module Search
    class Handler
      def initialize(client_class = Elasticsearch::Client, environment = ENV)
        @client_class = client_class
        @environment = environment
        @renderer = Renderer.new
      end

      def call(request_env)
        query = Query.new(extract_query_params(request_env['QUERY_STRING']))
        query.get_results(client_class.new(url: elasticsearch_url))

        [200, {'Content-Type' => 'text/html'}, [renderer.render_results(query)]]
      rescue Exception => e
        puts e.message
        puts e.backtrace.join("\n")

        [500, {'Content-Type' => 'text/plain'}, ['An error occurred']]
      end

      def extract_query_params(param_string)
        parsed = CGI::parse(param_string || '')
        parsed.keys.inject(Hash.new('')) do |params, key|
          # CGI::parse returns values in an array
          params[key] = parsed[key].first
          params
        end
      end

      private

      attr_reader :renderer, :client_class, :environment

      def elasticsearch_url
        @elasticsearch_url ||= JSON.parse(environment['VCAP_SERVICES'])['searchly'][0]['credentials']['uri']
      end
    end
  end
end
