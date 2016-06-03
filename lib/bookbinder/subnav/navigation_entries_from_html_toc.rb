require 'nokogiri'
require 'active_support/all'

module Bookbinder
  module Subnav
    class NavigationEntriesFromHtmlToc
      def initialize(fs)
        @fs = fs
        @external_link_check = %r{\Ahttps?://}
      end

      def get_links(section, output_locations)
        @section, @output_locations = section, output_locations

        doc = parse_toc_file
        set_anchor_values(doc.css('a'))

        gather_urls_and_texts(doc.css('body > ul'))
      end

      private

      attr_reader :fs, :section, :output_locations

      def parse_toc_file
        html = fs.read(
          File.join(
            output_locations.html_from_preprocessing_dir,
            section.destination_directory,
            'index.html')
        )
        Nokogiri::XML(html)
      end

      def set_anchor_values(anchors)
        anchors.each do |anchor|
          unless @external_link_check.match(anchor['href'])
            anchor['href'] = "/#{section.destination_directory}/#{anchor['href']}"
          end
        end
      end

      def gather_urls_and_texts(base_node)
        top_level_li = base_node.css("> li")
        top_level_li.map do |li|
          anchor = li.css('a')[0]
          href = anchor['href']
          text = anchor.inner_text
          ul = li.css('> ul')
          if ul.size > 0
            {url: href, text: text, nested_links: gather_urls_and_texts(ul)}
          else
            {url: href, text: text}
          end
        end
      end
    end
  end
end
