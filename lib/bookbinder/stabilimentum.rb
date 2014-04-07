class Spider
  class Stabilimentum # Decorates a piece of the web.
    FudgedUri = Struct.new(:path, :fragment, :to_s)

    def initialize(page)
      @page = page
    end

    def referer
      @page.referer
    end

    def not_found?
      @page.not_found?
    end

    def url
      @page.url
    end

    def has_target_for?(uri)
      id_selector   = uri.fragment
      name_selector = "[name=#{uri.fragment}]"

      @page.doc.css("##{id_selector}").any? || @page.doc.css(name_selector).any?
    rescue Nokogiri::CSS::SyntaxError
      false
    end

    def fragment_identifiers(targeting_locally: false)
      anchors.map { |anchor| appropriately_scoped_fragment_uri(anchor, targeting_locally) }.compact
    end

    private

    def appropriately_scoped_fragment_uri(anchor, targeting_locally)
      uri = URI anchor['href'].to_s
      uri if destination_scoped_appropriately?(uri, targeting_locally) && has_fragment(uri)
    rescue URI::InvalidURIError => e
      FudgedUri.new('', anchor['href'], anchor['href'])
    end

    def has_fragment(uri)
      !uri.fragment.to_s.empty?
    end

    def destination_scoped_appropriately?(uri, local_anchors_sought)
      local_anchors_sought ? uri.path.to_s.empty? : !uri.path.to_s.empty?
    end

    def anchors
      @page.doc ? @page.doc.css('a') : []
    end
  end
end
