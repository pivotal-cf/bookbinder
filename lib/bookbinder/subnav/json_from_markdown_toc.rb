require 'json'
require 'nokogiri'
require 'redcarpet'

module Bookbinder
  module Subnav
    class JsonFromMarkdownToc
      SubnavDuplicateLinkError = Class.new(RuntimeError)
      SubnavBrokenLinkError = Class.new(RuntimeError)
      SubnavRootMissingError = Class.new(RuntimeError)

      def initialize(fs)
        @fs = fs
        @renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new)
      end

      def get_links(product_config, output_locations)
        @source_for_site_gen = output_locations.source_for_site_generator
        @config = product_config

        root = absolute_source_from_path(Pathname(config.subnav_root))

        raise SubnavRootMissingError.new('Subnav root not found at: ' + config.subnav_root) if root.nil?

        @parsed_files = { Pathname(root) => '(root)'}

        {links: gather_urls_and_texts(root)}.to_json
      end

      attr_reader :fs, :source_for_site_gen, :renderer, :config

      private

      def get_html(md)
        Nokogiri::HTML(renderer.render(md))
      end

      def absolute_source_from_path(path)
        full_sources = fs.find_files_extension_agnostically(path, source_for_site_gen)
        full_sources.first
      end

      # href: ./cat/index.html
      # expanded href: my/cat/index.html
      # full source: my/cat/index.html.md.erb
      def gather_urls_and_texts(source)
        toc_md = fs.read(source)
        base_node = get_html(toc_md).css('html')

        nav_items(base_node).map do |element|
          href = element['href']
          expanded_href = (source.dirname + href).relative_path_from(source_for_site_gen)
          next_source = absolute_source_from_path(expanded_href)

          raise SubnavBrokenLinkError.new(<<-ERROR) unless next_source
Broken link found in subnav for product_id: #{config.id}

Link: #{expanded_href}
Source file: #{source}
          ERROR
          raise SubnavDuplicateLinkError.new(<<-ERROR) if @parsed_files.has_key?(next_source)
)
Duplicate link found in subnav for product_id: #{config.id}

Link: #{expanded_href}
Original file: #{@parsed_files[next_source]}
Current file: #{source}
          ERROR

          @parsed_files[next_source] = source
          nested_urls_and_texts = gather_urls_and_texts(next_source)
          nested_links = {}
          nested_links.merge!(nestedLinks: nested_urls_and_texts) unless nested_urls_and_texts.empty?

          {url: '/' + expanded_href.to_s, text: element.inner_text}.merge(nested_links)
        end
      end

      def nav_items(base_node)
        base_node.css('a.subnav')
      end
    end
  end
end
