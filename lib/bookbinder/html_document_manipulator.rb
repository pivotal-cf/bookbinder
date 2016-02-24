require 'nokogiri'

module Bookbinder
  class HtmlDocumentManipulator
    def set_attribute(document: nil,
                      selector: nil,
                      attribute: nil,
                      value: nil)
      doc = Nokogiri::HTML.fragment(document)
      node_set = doc.css(selector)
      node_set.attr(attribute, value)
      doc.to_html
    end

    def read_html_in_tag(document: nil, tag: nil)
      doc = Nokogiri::HTML(document)
      doc.css(tag).inner_html
    end
  end
end

