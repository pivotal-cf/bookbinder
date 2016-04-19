require 'elasticsearch'
require 'yaml'
require 'erb'

module Bookbinder
  module Search
    def self.call(env)
      client = Elasticsearch::Client.new log: true, url: JSON.parse(ENV['VCAP_SERVICES'])['searchly'][0]['credentials']['uri']
      query = env['QUERY_STRING'].split('&').detect { |s| s =~ /\Aq=/ }.split('=').last
      query_options = YAML.load_file(File.expand_path('../../search.yml', __FILE__))
      query_options['query']['query_string']['query'] = query
      results = client.search index: 'searching', body: query_options

      erb = ERB.new(File.read(File.expand_path('../../search-results.html.erb', __FILE__)))

      search_data = Result.new(
        query,
        results['hits']['total'],
        results['hits']['hits']
      )

      [200, {'Content-Type' => 'text/html'}, [search_data.render(erb)]]
    rescue Exception => e
      [500, {'Content-Type' => 'text/plain'}, [e.message + "\n" + e.backtrace.join("\n")]]
    end

    class Result < Struct.new(:query, :result_count, :search_results)
      def render(erb)
        erb.result(binding)
      end
    end
  end
end
