require 'json'
require 'nokogiri'

module Bookbinder
  module Preprocessing
    class JsonFromConfig
      def initialize(fs)
        @fs = fs
      end

      def get_links(subnav_config, source_for_site_gen)
        @source_for_site_gen = source_for_site_gen

        { links: get_links_and_headers(subnav_config) }.to_json
      end

      attr_reader :fs, :source_for_site_gen

      private

      def get_links_and_headers(config)
        menu_items = []

          config.topics.map do |topic|
          menu_items << { text: topic.title, title: true }

          links_from_toc_page = parse_toc_url(topic.toc_url)
          links_from_toc_page.each {|link| menu_items << link}
        end

        menu_items
      end

      def parse_toc_url(url)
        full_path_to_toc_file = File.join(source_for_site_gen.join(url))

        toc_text = if fs.file_exist?("#{full_path_to_toc_file}.md.erb")
          fs.read("#{full_path_to_toc_file}.md.erb")
        else
          fs.read("#{full_path_to_toc_file}.md")
        end

        toc_html = Nokogiri::HTML(toc_text)

        gather_urls_and_texts(toc_html.css('main'))
      end

      def gather_urls_and_texts(base_node)
        nav_exclusions = base_node.css("h2[class='nav-exclude'], ul[class='nav-exclude'], ol[class='nav-exclude']")
        all_headers_and_lists = base_node.css("h2, h2 + ul")
        headers_and_lists = all_headers_and_lists - nav_exclusions

        headers_and_lists.map do |element|
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
    end
  end
end
