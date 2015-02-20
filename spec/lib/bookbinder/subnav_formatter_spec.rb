require_relative '../../../lib/bookbinder/subnav_formatter'
require 'nokogiri'

module Bookbinder
  describe SubnavFormatter do
    describe 'formatting a subnav' do

      it 'applies the appropriate CSS classes, wraps divs, and creates anchor paths from root' do
        toc_text = File.read('spec/fixtures/subnav_templates/tocjs_subnav.html')
        expected_processed_toc_text = File.read('spec/fixtures/subnav_templates/formatted_tocjs_subnav.html')
        subnav_formatter = SubnavFormatter.new

        expect(subnav_formatter.format(toc_text, "sample-section").gsub(/\s+/, "")).to eq expected_processed_toc_text.gsub(/\s+/, "")
      end
    end
  end
end