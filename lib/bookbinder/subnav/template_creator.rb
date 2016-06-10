require 'erb'
require 'rack/utils'

module Bookbinder
  module Subnav
    class TemplateCreator
      def initialize(fs, output_locations)
        @fs = fs
        @output_locations = output_locations
      end

      def create(navigation_entries, subnav_spec)
        template_content = fs.read(template_path)
        links_template = ERB.new(fs.read(subnavs_path.join('_nav-links.erb')))

        populated_nav = ERB.new(template_content).result(LinkHolder.new(navigation_entries, links_template).get_binding)

        fs.write(text: populated_nav, to: subnav_destination(subnav_spec.subnav_name))
      end

      attr_reader :fs, :output_locations, :html_doc_manipulator

      private

      def subnavs_path
        output_locations.subnavs_for_layout_dir
      end

      def filename(name)
        "#{name}.erb"
      end

      def template_path
        subnavs_path.join('_subnav_template.erb')
      end

      def subnav_destination(name)
        subnavs_path.join(filename(name))
      end

      class LinkHolder
        def initialize(links, template)
          @links = links
          @template = template
        end

        attr_reader :links

        def get_binding
          binding
        end

        def render_links(some_links)
          @template.result(LinkHolder.new(some_links, @template).get_binding)
        end

        def submenu_class(link)
          'has_submenu' unless links?(link[:nested_links])
        end

        def links?(links)
          (links || []).empty?
        end

        def escape_html(str)
          Rack::Utils.escape_html(str)
        end
      end
    end
  end
end
