require 'nokogiri'
require 'active_support/all'

module Bookbinder
  class SubnavFormatter

    def get_links_as_json(raw_subnav_text, base_dirname)
      doc = Nokogiri::XML(raw_subnav_text)

      all_anchors = doc.css('a')
      all_anchors.each do |anchor|
        anchor['href'] = "/#{base_dirname}/#{anchor['href']}"
      end

      gather_urls_and_texts(doc.css('body > ul')).to_json
    end

    private

    def gather_urls_and_texts(base_node)
      top_level_li = base_node.css("> li")
      top_level_li.map do |li|
        anchor = li.css('a')[0]
        href = anchor['href']
        text = anchor.inner_text
        ul = li.css('> ul')
        if ul.size > 0
          {url: href, text: text, nestedLinks: gather_urls_and_texts(ul)}
        else
          {url: href, text: text}
        end
      end
    end
  end
end