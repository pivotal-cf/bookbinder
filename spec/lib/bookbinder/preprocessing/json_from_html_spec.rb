require_relative '../../../../lib/bookbinder/preprocessing/json_from_html'
require_relative '../../../../lib/bookbinder/html_document_manipulator'
require 'nokogiri'

module Bookbinder
  module Preprocessing
    describe JsonFromHtml do
      describe 'formatting a subnav' do
        def subnav_formatter
          JsonFromHtml.new
        end

        it 'applies the appropriate CSS classes, wraps divs, and creates anchor paths from root' do
          toc_text = File.read('spec/fixtures/subnav_templates/tocjs_subnav.html')
          expected_processed_toc_text = File.read('spec/fixtures/subnav_templates/formatted_tocjs_subnav.json')

          expect(subnav_formatter.get_links_as_json(toc_text, "sample-section").gsub(/\s+/, '')).to eq expected_processed_toc_text.gsub(/\s+/, "")
        end
      end
    end
  end
end
