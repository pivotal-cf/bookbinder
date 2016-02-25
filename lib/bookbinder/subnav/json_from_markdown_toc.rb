require 'json'
require 'nokogiri'
require 'redcarpet'

module Bookbinder
  module Subnav
    class JsonFromMarkdownToc
      SubnavDuplicateLinkError = Class.new(RuntimeError)
      SubnavBrokenLinkError = Class.new(RuntimeError)

      def initialize(fs)
        @fs = fs
        @renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new)
      end

      def get_links(product_config, output_locations)
        @parsed_files = Set.new

        @source_for_site_gen = output_locations.source_for_site_generator
        @config = product_config

        {links: gather_urls_and_texts(config.subnav_root)}.to_json
      end

      attr_reader :fs, :source_for_site_gen, :renderer, :config

      private

      def parse_toc_file(toc_file_path)
        toc_files = fs.find_files_extension_agnostically(toc_file_path, source_for_site_gen)
        toc_file = toc_files.first

        raise SubnavBrokenLinkError.new(toc_file_path) unless toc_file
        raise SubnavDuplicateLinkError.new(toc_file) if @parsed_files.include?(toc_file)

        @parsed_files << toc_file

        toc_md = fs.read(toc_file)
        get_html(toc_md)
      end

      def get_html(md)
        Nokogiri::HTML(renderer.render(md))
      end

      def gather_urls_and_texts(subnav_root)
        subnav_root = Pathname(subnav_root)

        base_node = parse_toc_file(subnav_root).css('html')

        nav_items(base_node).flat_map do |element|
          unless frontmatter_header?(element)
            a = element.at_css('a')
            next if a.nil?

            href = a['href']
            next if href.nil?

            expanded_url = subnav_root.dirname.join(href).to_s

            nested_urls_and_texts = gather_urls_and_texts(expanded_url)
            nested_links = {}
            nested_links.merge!(nestedLinks: nested_urls_and_texts) unless nested_urls_and_texts.empty?

            {url: '/' + expanded_url, text: element.inner_text}.merge(nested_links)
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
