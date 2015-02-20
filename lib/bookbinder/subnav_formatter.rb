require 'nokogiri'

module Bookbinder
  class SubnavFormatter

    def format(raw_subnav_text, base_dirname)
      doc = Nokogiri::XML(raw_subnav_text)
      containing_ul = doc.css('body > ul')
      containing_ul.add_class('menu')

      all_anchors = doc.css('a')
      all_anchors.each do |anchor|
        anchor['href'] = "/#{base_dirname}/#{anchor['href']}"
      end

      terminal_lis = doc.xpath('//li/ul/li[count(child::*) = 1]')
      terminal_lis.add_class('menu-link')

      non_leaf_lis = doc.css('ul > li:not(.menu-link)')
      non_leaf_lis.add_class('menu-item js-menu-item')

      top_level_menu_item_links = doc.css('ul > li:not(.menu-link) > a')
      top_level_menu_item_links.wrap('<div class="menu-title js-menu-title"></div>')

      nested_lists = doc.css('body ul > li ul')
      nested_lists.wrap('<div class="menu-content js-menu-content" aria-hidden="true"></div>')

      containing_ul.to_html
    end

  end
end