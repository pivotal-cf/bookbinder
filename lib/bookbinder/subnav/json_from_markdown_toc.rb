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
        @source_for_site_gen = output_locations.source_for_site_generator
        @config = product_config
        @parsed_files = { full_source_from_path(Pathname(config.subnav_root)).to_s => '(root)'}

        {links: gather_urls_and_texts(config.subnav_root)}.to_json
      end

      attr_reader :fs, :source_for_site_gen, :renderer, :config

      private

      def get_html(md)
        Nokogiri::HTML(renderer.render(md))
      end

      def full_source_from_path(path)
        full_sources = fs.find_files_extension_agnostically(path, source_for_site_gen)
        full_sources.first
      end

      # href: ./cat/index.html
      # expanded href: my/cat/index.html
      # full source: my/cat/index.html.md.erb
      def gather_urls_and_texts(current_expanded_href)
        current_expanded_path = Pathname(current_expanded_href)

        full_source = full_source_from_path(current_expanded_path)
        raise SubnavBrokenLinkError.new(<<-ERROR) unless full_source
Broken link found in subnav for product_id: #{config.id}

Link: #{current_expanded_href}
Source file: #{@parsed_files[current_expanded_href]}
        ERROR

        toc_md = fs.read(full_source)
        base_node = get_html(toc_md).css('html')

        nav_items(base_node).map do |element|
          a = element.at_css('a')
          href = a['href']

          next_expanded_href = current_expanded_path.dirname.join(href).to_s
          raise SubnavDuplicateLinkError.new(<<-ERROR) if @parsed_files.has_key?(next_expanded_href)
)
Duplicate link found in subnav for product_id: #{config.id}

Link: #{next_expanded_href}
Original file: #{@parsed_files[next_expanded_href]}
Current file: #{full_source}
          ERROR
          @parsed_files[next_expanded_href] = full_source

          nested_urls_and_texts = gather_urls_and_texts(next_expanded_href )
          nested_links = {}
          nested_links.merge!(nestedLinks: nested_urls_and_texts) unless nested_urls_and_texts.empty?

          {url: '/' + next_expanded_href , text: element.inner_text}.merge(nested_links)
        end
      end

      def nav_items(base_node)
        base_node.xpath('/html/body/h2[a[@href]]') # - base_node.css(*exclusions)
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
