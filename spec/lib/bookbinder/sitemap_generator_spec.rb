require 'spec_helper'

module Bookbinder
  describe SitemapGenerator do
    let(:sitemap_file) { File.join Dir.mktmpdir, 'sitemap.xml' }
    let(:links) { [
        'http://www.example.com/foo/bar.html',
        'http://www.example.com/grep/grok.cf',
        'http://www.example.com/cgi-bin/index.pl'
    ]}
    let(:expected_xml) {
      <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>http://www.example.com/foo/bar.html</loc>
    <changefreq>daily</changefreq>
  </url>
  <url>
    <loc>http://www.example.com/grep/grok.cf</loc>
    <changefreq>daily</changefreq>
  </url>
  <url>
    <loc>http://www.example.com/cgi-bin/index.pl</loc>
    <changefreq>daily</changefreq>
  </url>
</urlset>
      XML
    }
    subject { described_class.new }

    it 'writes the links passed to it as valid XML' do
      subject.generate(links, sitemap_file)
      generated_sitemap = File.read sitemap_file
      expect(generated_sitemap).to eq(expected_xml)
    end
  end
end
