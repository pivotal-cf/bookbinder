require 'nokogiri'

module Bookbinder
  class SitemapGenerator
    def generate(links, sitemap_file)
      builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
        xml.urlset('xmlns' => 'http://www.sitemaps.org/schemas/sitemap/0.9') {
          links.each do |link|
            xml.url {
              xml.loc link
              xml.changefreq 'daily'
            }
          end
        }
      end
      File.write(sitemap_file, builder.to_xml)
    end
  end
end
