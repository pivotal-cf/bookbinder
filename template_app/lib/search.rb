require 'elasticsearch'
require 'yaml'
require 'erb'

module Bookbinder
  module Search
    def self.call(env)
      client = Elasticsearch::Client.new log: true, url: JSON.parse(ENV['VCAP_SERVICES'])['searchly'][0]['credentials']['uri']
      query = env['QUERY_STRING'].split('&').detect { |s| s =~ /\Aq=/ }.split('=').last
      query_options = YAML.load_file(File.expand_path('../../search.yml', __FILE__))
      query_options['query_string']['query'] = query
      results = client.search index: 'searching', body: query_options

      erb = ERB.new(File.read(File.expand_path('../../search-results.html.erb', __FILE__)))

      search_data = {
        query: query,
        total_results: results['hits']['total'],
        search_results: results['hits']['hits']
      }

      [200, {'Content-Type' => 'application/json'}, [erb.result(search_data)]]
    end
  end
end
