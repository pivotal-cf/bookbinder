require 'erb'
require 'rack/utils'

module Bookbinder
  module Search
    class Renderer
      def initialize
        @template = ERB.new(File.read(File.expand_path('../../../search-results.html.erb', __FILE__)))
      end

      def render_results(result)
        result_binding = result.instance_eval { binding }

        render_layout do
          @template.result(result_binding)
        end
      end

      private

      def render_layout
        layout.result(binding)
      end

      def layout
        @layout ||= ERB.new(File.read(File.expand_path('../../../public/search.html', __FILE__)))
      end
    end
  end
end
