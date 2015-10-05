require 'json'
require 'nokogiri'
require 'redcarpet'

module Bookbinder
  module Preprocessing
    class JsonFromConfig
      def initialize(fs)
        @fs = fs
        @renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new)
      end

      def get_links(subnav_config, source_for_site_gen)
        @source_for_site_gen = source_for_site_gen

        { links: get_links_and_headers(subnav_config) }.to_json
      end

      attr_reader :fs, :source_for_site_gen, :renderer

      private

      def get_links_and_headers(config)
        menu_items = []

        config.topics.map do |topic|
          menu_items << { text: topic.title, title: true }
          menu_items << { url: topic.toc_url, text: topic.toc_nav_name }

          links_from_toc_page = parse_toc_url(topic.toc_url)
          links_from_toc_page.each {|link| menu_items << link}
        end

        menu_items
      end

      def parse_toc_url(url)
        full_path_to_toc_file = File.join(source_for_site_gen.join(url))

        toc_md = if fs.file_exist?("#{full_path_to_toc_file}.md.erb")
          fs.read("#{full_path_to_toc_file}.md.erb")
        else
          fs.read("#{full_path_to_toc_file}.md")
        end

        toc_html = get_html(toc_md)

        gather_urls_and_texts(toc_html.css('html'))
      end

      def get_html(md)
        Nokogiri::HTML(renderer.render(md))
      end

      def gather_urls_and_texts(base_node)
        nav_items(base_node).map do |element|
          if element.name == 'h2'
            {text: element.inner_html}
          else
            list_elements = element.css('li > a')
            list_elements.map do |li|
              {url: li['href'], text: li.inner_text}
            end
          end
        end.flatten
      end

      def nav_items(base_node)
        base_node.css("h2, h2 + ul") - base_node.css(".nav-exclude")
      end
    end
  end
end
