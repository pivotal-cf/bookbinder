class Spider
  private

  class Stabilimentum # Decorates a piece of the web.
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
      anchors.map do |anchor|
        uri = URI anchor['href'].to_s
        uri if target_scoped_appropriately?(uri, targeting_locally) && has_fragment(uri)
      end.compact
    end

    private

    def has_fragment(uri)
      !uri.fragment.to_s.empty?
    end

    def target_scoped_appropriately?(uri, local_targets_desired)
      local_targets_desired ? uri.path.to_s.empty? : !uri.path.to_s.empty?
    end

    def anchors
      @page.doc ? @page.doc.css('a') : []
    end
  end
end
