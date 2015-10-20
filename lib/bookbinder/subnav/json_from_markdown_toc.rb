require 'json'
require 'nokogiri'
require 'redcarpet'

module Bookbinder
  module Subnav
    class JsonFromMarkdownToc
      def initialize(fs)
        @fs = fs
        @renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new)
      end

      def get_links(subnav_config, output_locations)
        @source_for_site_gen = output_locations.source_for_site_generator
        @config = subnav_config

        { links: get_links_and_headers }.to_json
      end

      attr_reader :fs, :source_for_site_gen, :renderer, :config

      private

      def get_links_and_headers
        menu_items = []

        config.topics.map do |topic|
          menu_items << { text: topic.title, title: true }
          menu_items << { url: "/#{topic.toc_path}.html", text: topic.toc_nav_name }

          links_from_toc_page = parse_toc_file(topic)
          links_from_toc_page.each {|link| menu_items << link}
        end

        menu_items
      end

      def parse_toc_file(topic)
        toc_files = fs.find_files_extension_agnostically(topic.toc_path, source_for_site_gen)
        toc_md = fs.read(toc_files.first)

        toc_html = get_html(toc_md)

        gather_urls_and_texts(toc_html.css('html'), topic)
      end

      def get_html(md)
        Nokogiri::HTML(renderer.render(md))
      end

      def gather_urls_and_texts(base_node, topic)
        nav_items(base_node).map do |element|
          if element.name == 'h2' && !frontmatter_header?(element)
            {text: element.inner_html}
          else
            list_elements = element.css('li > a', 'li > p > a')
            list_elements.map do |li|
              { url: "/#{topic.toc_path.dirname.join(li['href'])}", text: li.inner_text }
            end
          end
        end.flatten
      end

      def nav_items(base_node)
        base_node.css('h2, ul') - base_node.css(*exclusions)
      end

      def exclusions
        @exclusions ||= config.subnav_exclusions << '.nav-exclude'
      end

      def frontmatter_header?(element)
        element.inner_html.include?('title: ')
      end
    end
  end
end
