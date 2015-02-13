require 'spec_helper'

module Bookbinder
  describe Sieve do
    def new_page(uri_str, options)
      Spider::Stabilimentum.new(
        Anemone::Page.new(
          URI(uri_str),
          { headers: {'content-type' => ['text/html']},
            code: 200 }.
          merge(options)
        )
      )
    end

    describe '#links_from' do
      let(:sieve) { Sieve.new(domain: root_page_url) }
      let(:root_page_url) { 'http://example.com/' }

      context 'when the page is found' do
        context 'and it has a valid html body' do
          it 'returns the arrays passed to it, filled with links from the given page' do
            broken_links, working_links = sieve.links_from(
              new_page(root_page_url, body: '<a href="#this-is-broken"/>'),
              first_pass = true
            )

            expect(broken_links).to eq(["/ => #this-is-broken"])
            expect(working_links).to eq([root_page_url])
          end
        end
      end

      context 'when the page is not found' do
        it 'returns the arrays passed to it, filled with links from the given page' do
          broken_links, working_links = sieve.links_from(
            new_page("#{root_page_url}fake", code: 404, referer: root_page_url),
            first_pass = true
          )
          expect(broken_links).to eq(['/ => http://example.com/fake'])
          expect(working_links).to eq([])
        end
      end
    end
  end
end
