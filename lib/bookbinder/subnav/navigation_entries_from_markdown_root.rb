require 'json'
require 'nokogiri'
require 'redcarpet'

module Bookbinder
  module Subnav
    class NavigationEntriesFromMarkdownRoot
      SubnavDuplicateLinkError = Class.new(RuntimeError)
      SubnavBrokenLinkError = Class.new(RuntimeError)
      SubnavRootMissingError = Class.new(RuntimeError)

      def initialize(fs, require_valid_subnav_links)
        @fs = fs
        @require_valid_subnav_links = require_valid_subnav_links
        @renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new)
      end

      def get_links(product_config, output_locations)
        @source_for_site_gen = output_locations.source_for_site_generator
        @config = product_config

        root = absolute_source_from_path(Pathname(config.subnav_root))

        if root.nil?
          if @require_valid_subnav_links
            raise SubnavRootMissingError.new('Subnav root not found at: ' + config.subnav_root)
          else
            return []
          end
        end

        @parsed_files = {Pathname(root) => '(root)'}

        gather_urls_and_texts(root)
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
          nested_links = {}

          no_children = false
          no_children ||= validate_no_broken_link(expanded_href, next_source, source)
          no_children ||= validate_no_duplicate_link(expanded_href, next_source, source)

          unless no_children
            @parsed_files[next_source] = source
            nested_urls_and_texts = gather_urls_and_texts(next_source)
            nested_links.merge!(nested_links: nested_urls_and_texts) unless nested_urls_and_texts.empty?
          end

          {url: '/' + expanded_href.to_s, text: element.inner_text}.merge(nested_links)
        end
      end

      def validate_no_duplicate_link(expanded_href, next_source, source)
        if @parsed_files.has_key?(next_source)
          if @require_valid_subnav_links
            raise SubnavDuplicateLinkError.new(<<-ERROR)
)
Duplicate link found in subnav for product_id: #{config.id}

Link: #{expanded_href}
Original file: #{@parsed_files[next_source]}
Current file: #{source}
            ERROR
          else
            no_children = true
          end
        end
        no_children
      end

      def validate_no_broken_link(expanded_href, next_source, source)
        unless next_source
          if @require_valid_subnav_links
            raise SubnavBrokenLinkError.new(<<-ERROR)
Broken link found in subnav for product_id: #{config.id}

Link: #{expanded_href}
Source file: #{source}
            ERROR
          else
            no_children = true
          end
        end
        no_children
      end

      def nav_items(base_node)
        base_node.css('a.subnav')
      end
    end
  end
end
