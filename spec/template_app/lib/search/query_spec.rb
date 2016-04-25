require_relative '../../../../template_app/lib/search/query'

module Bookbinder::Search
  describe Query do
    subject(:query) { Query.new(mock_client) }
    let(:mock_client) { double(:mock_client) }

    describe 'searching' do
      it 'returns search results' do
        allow(mock_client).to receive(:search) do
          {
            'hits' => {
              'total' => 3,
              'hits' => [
                {
                  '_source' => {
                    'url' => 'hi.html',
                    'title' => 'Hi'
                  },
                  'highlight' => {
                    'text' => [' Im a highlight ']
                  }
                },
                {
                  '_source' => {
                    'url' => 'bye.html',
                    'title' => 'Bye'
                  },
                  'highlight' => {
                    'text' => [' Im bye highlight ']
                  }
                },
                {
                  '_source' => {
                    'url' => 'another.html',
                    'title' => 'Another'
                  },
                  'highlight' => {
                    'text' => [' Im another highlight ']
                  }
                },
              ]
            }
          }
        end

        results = query.search('q' => 'search')

        expect(results.query).to eq('search')
        expect(results.hit_count).to eq(3)
        expect(results.page_number).to eq(1)

        expect(results.hits[0].title).to eq('Hi')
        expect(results.hits[0].url).to eq('hi.html')
        expect(results.hits[0].text).to eq('Im a highlight')

        expect(results.hits[1].title).to eq('Bye')
        expect(results.hits[2].title).to eq('Another')

        expect(mock_client).to have_received(:search).with({index: 'searching', body: {
          'query' => {'query_string' => {'query' => 'search', 'default_field' => 'text'}},
          'from' => 0,
          'size' => 10,
          '_source' => ['url', 'title'], 'highlight' => {'fields' => {'text' => {'type' => 'plain'}}}
        }})
      end

      it 'returns an empty result set for a blank query' do
        allow(mock_client).to receive(:search) { nil }

        results = query.search('q' => nil)

        expect(results.hit_count).to eq(0)

        expect(mock_client).not_to have_received(:search)
      end

      it 'should get a specific page of results' do
        allow(mock_client).to receive(:search) do
          {
            'hits' => {
              'total' => 23,
              'hits' => [
                {
                  '_source' => {
                    'url' => 'hi.html',
                    'title' => 'Hi'
                  },
                  'highlight' => {
                    'text' => [' Im a highlight ']
                  }
                },
                {
                  '_source' => {
                    'url' => 'bye.html',
                    'title' => 'Bye'
                  },
                  'highlight' => {
                    'text' => [' Im bye highlight ']
                  }
                },
                {
                  '_source' => {
                    'url' => 'another.html',
                    'title' => 'Another'
                  },
                  'highlight' => {
                    'text' => [' Im another highlight ']
                  }
                },
              ]
            }
          }
        end

        results = query.search('q' => 'search', 'page' => '3')

        expect(results.hit_count).to eq(23)
        expect(results.page_number).to eq(3)

        expect(mock_client).to have_received(:search).with({
          index: 'searching',
          body: {
            'query' => {
              'query_string' => {
                'query' => 'search',
                'default_field' => 'text'
              }
            },
            'from' => 20,
            'size' => 10,
            '_source' => [ 'url', 'title' ],
            'highlight' => {
              'fields' => {
                'text' => {
                  'type' => 'plain'
                }
              }
            }
          }
        })
      end
    end
  end
end
