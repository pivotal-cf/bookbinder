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
      anchor_uris.select { |u| good_uri?(u, targeting_locally) }
    end

    private

    def convert_to_uri(anchor)
      URI anchor['href'].to_s
    rescue URI::InvalidURIError
      create_fudged_uri(anchor['href'])
    end

    def good_uri?(uri, targeting_locally)
      destination_scoped_appropriately?(uri, targeting_locally) && has_fragment(uri)
    end

    def has_fragment(uri)
      !uri.fragment.to_s.empty?
    end

    def destination_scoped_appropriately?(uri, local_anchors_sought)
      local_anchors_sought ? uri.path.to_s.empty? : !uri.path.to_s.empty?
    end

    def anchor_uris
      anchors = @page.doc ? @page.doc.css('a') : []
      anchors.map { |a| convert_to_uri(a) }
    end

    def create_fudged_uri(target)
      path = target.split('#')[0]
      fragment = target.include?('#') ? '#' + target.split('#')[1] : nil
      FudgedUri.new(path, fragment, target)
    end
  end
end
