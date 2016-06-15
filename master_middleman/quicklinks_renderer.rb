require 'nokogiri'
require 'redcarpet'

class QuicklinksRenderer < Redcarpet::Render::Base
  class BadHeadingLevelError < StandardError; end

  attr_reader :vars

  def initialize(template_variables)
    super()
    @vars = template_variables
  end

  def doc_header
    @items = []
    @items[1] = document.css('ul').first
    nil
  end

  def doc_footer
    document.css('.quick-links').to_html if any_headers?
  end

  def header(text, header_level)
    return unless [2, 3].include?(header_level)
    return unless anchor_for(text)

    li = Nokogiri::XML::Node.new('li', document)
    li.add_child anchor_for(text)
    last_list_of_level(header_level-1).add_child(li)
    @items[header_level] = li
    nil
  rescue BadHeadingLevelError => e
    raise BadHeadingLevelError.new "The header \"#{text}\", which is at level #{e.message}, has no higher-level headers occurring before it."
  end

  private

  def any_headers?
    @items[2]
  end

  def anchor_for(text)
    text = ERB.new(text).result(binding)
    doc = Nokogiri::HTML(text)
    target_anchor = doc.css('a').first
    return unless target_anchor && target_anchor['id']
    return if (target_anchor['class'] || '').match(/\bno-quick-link\b/)

    anchor = Nokogiri::XML::Node.new('a', document)
    anchor['href'] = "##{target_anchor['id']}"
    anchor.content = doc.text.strip
    anchor
  end

  def last_list_of_level(n)
    item = @items[n]
    raise BadHeadingLevelError.new("#{n+1}") unless item
    return item if item.name == 'ul'

    item.add_child('<ul>') unless item.css('ul').any?
    @items[n] = item.css('ul').first
  end

  def document
    builder.doc
  end

  def builder
    @builder ||= Nokogiri::HTML::Builder.new(&base_quicklinks_doc)
  end

  def base_quicklinks_doc
    Proc.new do |html|
      html.div(class: 'quick-links') {
        html.ul
      }
    end
  end
end
