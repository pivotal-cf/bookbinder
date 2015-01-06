module Bookbinder
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
        id_selector = uri.fragment
        name_selector = "[name=#{uri.fragment}]"

        @page.doc.css("##{id_selector}").any? || @page.doc.css(name_selector).any?
      rescue Nokogiri::CSS::SyntaxError
        false
      end

      def fragment_identifiers(targeting_locally: false)
        if targeting_locally
          fragment_anchor_uris.select { |uri| uri.path.empty? }
        else
          fragment_anchor_uris.reject { |uri| uri.path.empty? }
        end
      end

      private

      def fragment_anchor_uris
        anchors = @page.doc ? @page.doc.css('a') : []
        anchors.map { |a| convert_to_uri(a) }.select { |u| u.fragment }
      end

      def convert_to_uri(anchor)
        URI anchor['href'].to_s
      rescue URI::InvalidURIError
        create_fudged_uri(anchor['href'])
      end

      def create_fudged_uri(target)
        path = target.split('#')[0]
        fragment = target.include?('#') ? '#' + target.split('#')[1] : nil
        FudgedUri.new(path, fragment, target)
      end
    end
  end
end
