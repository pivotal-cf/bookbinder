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

      def get_links(product_config, output_locations)
        @source_for_site_gen = output_locations.source_for_site_generator
        @config = product_config

        { links: parse_toc_file(Pathname(config.subnav_root)) }.to_json
      end

      attr_reader :fs, :source_for_site_gen, :renderer, :config

      private

      def parse_toc_file(subnav_root)
        toc_files = fs.find_files_extension_agnostically(subnav_root, source_for_site_gen)
        toc_md = fs.read(toc_files.first)

        toc_html = get_html(toc_md)

        gather_urls_and_texts(subnav_root, toc_html.css('html'))
      end

      def get_html(md)
        Nokogiri::HTML(renderer.render(md))
      end

      def gather_urls_and_texts(subnav_root, base_node)
        nav_items(base_node).flat_map do |element|
          unless frontmatter_header?(element)
            href = element.at_css('a')['href']
            expanded_url = '/' + subnav_root.dirname.join(href).to_s
            {url: expanded_url, text: element.inner_text}
          end
        end.compact
      end

      def nav_items(base_node)
        base_node.css('h2') - base_node.css(*exclusions)
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
