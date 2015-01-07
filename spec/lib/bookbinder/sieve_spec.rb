require 'spec_helper'

module Bookbinder
  describe Sieve do
    describe '#links_from' do
      let(:sieve) { Sieve.new(domain: root_page_url) }
      let(:page) { double(localized_links_in_stylesheets: []) }
      let(:root_page_url) { 'http://example.com/' }

      context 'when the page is found' do
        before do
          allow(page).to receive(:not_found?).and_return(false)
          allow(page).to receive(:url).and_return(root_page_url)
        end

        context 'and it has a valid html body' do
          let(:frags) { [URI('#this-is-broken')] }

          before do
            allow(page).to receive(:fragment_identifiers).and_return(frags)
            allow(page).to receive(:has_target_for?).with(frags.first).and_return(false)
          end

          it 'returns the arrays passed to it, filled with links from the given page' do
            broken_links, working_links = sieve.links_from(page, true)

            expect(broken_links).to eq(["/ => #{frags.pop}"])
            expect(working_links).to eq([root_page_url])
          end
        end
      end

      context 'when the page is not found' do
        before do
          allow(page).to receive(:not_found?).and_return(true)
          allow(page).to receive(:url).and_return("#{root_page_url}fake")
          allow(page).to receive(:referer).and_return(root_page_url)
        end

        it 'returns the arrays passed to it, filled with links from the given page' do
          is_second_pass = true
          broken_links, working_links = sieve.links_from(page, is_second_pass)

          expect(broken_links).to eq(['/ => http://example.com/fake'])
          expect(working_links).to eq([])
        end
      end
    end
  end
end
