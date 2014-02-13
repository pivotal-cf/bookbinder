class Spider
  private

  # Please direct anger/frustration regarding this name to
  # Gavin Morgan, mailto: gmorgan@gopivotal.com
  class Stabilimentum # Decorates a piece of the web.
    def initialize(page)
      @page = page
    end

    def not_found?
      @page.not_found?
    end

    def url
      @page.url
    end

    def has_target_for?(fragment)
      id_selector = fragment
      name_selector = "[name=#{fragment.to_s.gsub('#', '')}]"

      @page.doc.css(id_selector).any? || @page.doc.css(name_selector).any?
    rescue Nokogiri::CSS::SyntaxError
      false
    end

    def fragment_identifiers(targeting_locally: false)
      fragment_regex = targeting_locally ? /^#.*/ : /.+#.*/

      anchors.reduce([]) do |identifiers, anchor|
        id = fragment_id(anchor, fragment_regex)
        identifiers << id if id
        identifiers
      end
    end

    private

    def anchors
      @page.doc ? @page.doc.css('a') : []
    end

    def fragment_id(anchor, regexp)
      if anchor['href']
        possible_tag = anchor['href'].match(regexp).to_s
        possible_tag unless possible_tag.empty?
      end
    end
  end
end
