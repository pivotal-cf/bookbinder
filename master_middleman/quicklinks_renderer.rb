require 'redcarpet'

class QuicklinksRenderer < Redcarpet::Render::Base
  def doc_header
    @items = []
    @items[1] = document.css('ul').first
    nil
  end

  def doc_footer
    document.css('.quick-links').to_html if any_headers?
  end

  def header(text, header_level, anchor)
    return unless [2, 3].include?(header_level)
    return unless anchor_for(text)

    li = Nokogiri::XML::Node.new('li', document)
    li.add_child anchor_for(text)
    last_list_of_level(header_level-1).add_child(li)
    @items[header_level] = li
    nil
  end

  private

  def any_headers?
    @items[2]
  end

  def anchor_for(text)
    doc = Nokogiri::HTML(text)
    target_anchor = doc.css('a').first
    return unless target_anchor && target_anchor['id']

    anchor = Nokogiri::XML::Node.new('a', document)
    anchor['href'] = "##{target_anchor['id']}"
    anchor.content = doc.text.strip
    anchor
  end

  def last_list_of_level(n)
    item = @items[n]
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
