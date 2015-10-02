require 'nokogiri'
require 'json'

module Bookbinder
  module Preprocessing
    class JsonFromTocUrl
      def initialize(fs)
        @fs = fs
      end

      def parse(toc_url)
        toc_text = fs.read(toc_url)

        doc = Nokogiri::HTML(toc_text)

        get_links_as_json(doc)
      end

      def get_links_as_json(doc)
        {links: gather_urls_and_texts(doc.css('main'))}.to_json
      end

      attr_reader :fs

      private

      def gather_urls_and_texts(base_node)
        headers_and_lists = base_node.css('h2, h2 + ul')

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
