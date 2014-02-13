require 'spec_helper'

describe Sieve do
  describe '#links_into' do
    let(:sieve) { Sieve.new }
    let(:page) { double }
    let(:page_url) { 'example.com' }

    context 'when the page is found' do
      before do
        page.stub(:not_found?) { false }
        page.stub(:url) { page_url }
        page.stub(:fragment_identifiers) { frags }
      end

      context 'and it has a valid html body' do
        let(:frags) { ['#this-is-broken'] }

        before do
          page.stub(:has_target_for?).with('#this-is-broken').and_return false
        end

        it 'returns the arrays passed to it, filled with links from the given page' do
          broken_links = []
          working_links = []

          sieve.links_into page, broken_links, working_links, true

          broken_links.should =~ ['#this-is-broken']
          working_links.should =~ [page_url]
        end
      end

      context 'and it does not have a valid html body' do
        let(:frags) {[]}

        it 'does not modify the arrays' do
          broken_links = ['abc']
          working_links = ['def']

          sieve.links_into page, broken_links, working_links, true

          broken_links.should == ['abc']
          working_links.should == ['def', page_url]
        end

      end
    end
    context 'when the page is not found' do

      before do
        page.stub(:not_found?).and_return { true }
        page.stub(:url).and_return { 'example.com/fake' }
      end

      it 'returns the arrays passed to it, filled with links from the given page' do
        broken_links = []
        working_links = []

        sieve.links_into page, broken_links, working_links, true

        broken_links.should =~ ['example.com/fake']
        working_links.should =~ []
      end
    end
  end
end
