require 'elasticsearch'
require 'yaml'
require 'erb'

module Bookbinder
  module Search
    def self.call(env)
      search_data = search(get_search_query(env['QUERY_STRING']))

      erb = ERB.new(File.read(File.expand_path('../../search-results.html.erb', __FILE__)))

      [200, {'Content-Type' => 'text/html'}, [search_data.render(erb)]]
    rescue Exception => e
      puts e.message
      puts e.backtrace.join("\n")

      [500, {'Content-Type' => 'text/plain'}, ['An error occurred']]
    end

    def self.search(query)
      return Result.new(query, 0, []) if query == ''

      client = search_client

      query_options = YAML.load_file(File.expand_path('../../search.yml', __FILE__))
      query_options['query']['query_string']['query'] = query
      results = client.search index: 'searching', body: query_options

      Result.new(
        query,
        results['hits']['total'],
        results['hits']['hits']
      )
    end

    def self.get_search_query(query_string)
      q_param = query_string.split('&').detect { |s| s =~ /\Aq=/ }

      return '' if q_param.nil?

      q_param.split('=')[1] || ''
    end

    def self.search_client
      Elasticsearch::Client.new url: JSON.parse(ENV['VCAP_SERVICES'])['searchly'][0]['credentials']['uri']
    end

    Result = Struct.new(:query, :result_count, :search_results) do
      def render(erb)
        bind = binding
        render_layout do
          erb.result(bind)
        end
      end

      def render_layout
        ERB.new(self.class.layout_content).result(binding)
      end

      def self.layout_content
        File.read(File.expand_path('../../public/search.html', __FILE__))
      end
    end
  end
end
