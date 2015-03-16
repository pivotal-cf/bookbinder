require 'nokogiri'

module Bookbinder
  class SitemapGenerator
    def generate(links)
      Nokogiri::XML::Builder.new(encoding: 'UTF-8') { |xml|
        xml.urlset('xmlns' => 'http://www.sitemaps.org/schemas/sitemap/0.9') {
          links.each do |link|
            xml.url {
              xml.loc link
              xml.changefreq 'daily'
            }
          end
        }
      }.to_xml
    end
  end
end
