require 'spec_helper'

describe Sieve do
  describe '#links_from' do
    let(:sieve) { Sieve.new(domain: root_page_url) }
    let(:page) { double }
    let(:root_page_url) { 'http://example.com/' }

    context 'when the page is found' do
      before do
        page.stub(:not_found?) { false }
        page.stub(:url) { root_page_url }
        page.stub(:fragment_identifiers) { frags }
        page.stub(:localized_links_in_stylesheets) {[]}
      end

      context 'and it has a valid html body' do
        let(:frags) { [URI('#this-is-broken')] }

        before do
          page.stub(:has_target_for?).with(frags.first).and_return false
        end

        it 'returns the arrays passed to it, filled with links from the given page' do
          broken_links, working_links = sieve.links_from page, true

          broken_links.should =~ ["/ => #{frags.pop}"]
          working_links.should =~ [root_page_url]
        end
      end
    end

    context 'when the page is not found' do
      before do
        page.stub(:not_found?).and_return { true }
        page.stub(:url).and_return { "#{root_page_url}fake" }
        page.stub(:referer).and_return { root_page_url }
      end

      it 'returns the arrays passed to it, filled with links from the given page' do
        is_second_pass = true
        broken_links, working_links = sieve.links_from page, is_second_pass

        broken_links.should =~ ['/ => http://example.com/fake']
        working_links.should =~ []
      end
    end
  end
end
