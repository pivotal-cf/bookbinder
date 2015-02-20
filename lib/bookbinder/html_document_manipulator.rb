require 'nokogiri'

module Bookbinder
  class HtmlDocumentManipulator
    def insert_text_after_selector(text: nil, document: nil, selector: nil)
      doc = Nokogiri::HTML.fragment(document)
      node_set = doc.css(selector)
      node_set.each do |node|
        node.add_child(text)
      end
      doc.to_html
    end
  end
end

