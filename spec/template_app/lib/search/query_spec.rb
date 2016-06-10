require_relative '../../../../template_app/lib/search/query'

module Bookbinder::Search
  describe Query do
    it 'extracts default params with search_term' do
      query = Query.new('q' => 'foo')
      expect(query.search_term).to eq('foo')
      expect(query.product_name).to be_nil
      expect(query.product_version).to be_nil
      expect(query.page_number).to eq(1)
    end

    it 'extracts product name' do
      query = Query.new('product_name' => 'hi there')
      expect(query.product_name).to eq('hi there')
    end

    it 'extracts a product version when there is a product name' do
      query = Query.new('product_name' => 'hello', 'product_version' => 'v2344')
      expect(query.product_version).to eq('v2344')
    end

    it 'does not extract a product version without a product name' do
      query = Query.new('product_version' => 'v532')
      expect(query.product_version).to be_nil
    end

    it 'extracts a specific page number' do
      query = Query.new('q' => 'foo', 'page' => '6')
      expect(query.page_number).to eq(6)
    end

    it 'should fall back to the first page on an unknown page' do
      query = Query.new('q' => 'foo', 'page' => 'hi')
      expect(query.page_number).to eq(1)
    end

    it 'goes to the first page on an empty search term' do
      query = Query.new('page' => '234')
      expect(query.page_number).to eq(1)
    end

    it 'determines full query options' do
      query = Query.new('q' => 'bar', 'product_name' => 'foo', 'product_version' => 'v2', 'page' => '34')
      expect(query.query_options).to eq({
        'query' => { 'bool' => {
          'should' => {'simple_query_string' => {'query' => 'bar', 'fields' => ['text', 'title^10']}},
          'filter' => { 'bool' => { 'must' => [{'term' => { 'product_name' => 'foo'}}, { 'term' => { 'product_version' => 'v2' }}]}},
          'minimum_should_match' => 1
      }},
        'from' => 330,
        'size' => 10,
        '_source' => ['url', 'title', 'product_name', 'product_version'], 'highlight' => {'fields' => {'text' => {'type' => 'plain'}}}
      })
    end

    it 'gets query options that only filter by product name' do
      query = Query.new('q' => 'bar', 'product_name' => 'foo', 'page' => '34')
      expect(query.query_options).to eq({
        'query' => { 'bool' => {
          'should' => {'simple_query_string' => {'query' => 'bar', 'fields' => ['text', 'title^10']}},
          'filter' => { 'bool' => { 'must' => [{'term' => { 'product_name' => 'foo' }}]}},
          'minimum_should_match' => 1
        }},
        'from' => 330,
        'size' => 10,
        '_source' => ['url', 'title', 'product_name', 'product_version'], 'highlight' => {'fields' => {'text' => {'type' => 'plain'}}}
      })
    end

    it 'gets query options without a filter when no product name is given' do
      query = Query.new('q' => 'bar', 'page' => '34')
      expect(query.query_options).to eq({
        'query' => { 'bool' => {
          'should' => {'simple_query_string' => {'query' => 'bar', 'fields' => ['text', 'title^10']}},
          'minimum_should_match' => 1
        }},
        'from' => 330,
        'size' => 10,
        '_source' => ['url', 'title', 'product_name', 'product_version'], 'highlight' => {'fields' => {'text' => {'type' => 'plain'}}}
      })
    end

    describe 'searching' do
      let(:mock_client) { double(:mock_client, search: nil) }

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

        query = Query.new('q' => 'search')
        query.get_results(mock_client)

        expect(query.result_count).to eq(3)

        expect(query.result_list[0].title).to eq('Hi')
        expect(query.result_list[0].url).to eq('hi.html')
        expect(query.result_list[0].text).to eq('Im a highlight')

        expect(query.result_list[1].title).to eq('Bye')
        expect(query.result_list[2].title).to eq('Another')
      end

      it 'returns an empty result set for a blank query' do
        query = Query.new('q' => '')
        query.get_results(mock_client)

        expect(query.result_count).to eq(0)

        expect(mock_client).not_to have_received(:search)
      end

      it 'returns an empty result set for a missing query' do
        query = Query.new({})
        query.get_results(mock_client)

        expect(query.result_count).to eq(0)

        expect(mock_client).not_to have_received(:search)
      end

      describe 'page_window' do
        it 'shows a single page' do
          allow(mock_client).to receive(:search) do
            {
              'hits' => {
                'total' => 10,
                'hits' => []
              }
            }
          end

          query = Query.new('q' => 'foo', 'page' => '1')
          query.get_results(mock_client)

          expect(query.page_window).to eq([1])
        end

        it 'shows the first 5 pages' do
          allow(mock_client).to receive(:search) do
            {
              'hits' => {
                'total' => 100,
                'hits' => []
              }
            }
          end

          query = Query.new('q' => 'foo', 'page' => '1')
          query.get_results(mock_client)

          expect(query.page_window).to eq([1, 2, 3, 4, 5])
        end

        it 'shows the 5 surrounding pages' do
          allow(mock_client).to receive(:search) do
            {
              'hits' => {
                'total' => 100,
                'hits' => []
              }
            }
          end

          query = Query.new('q' => 'foo', 'page' => '5')
          query.get_results(mock_client)

          expect(query.page_window).to eq([3, 4, 5, 6, 7])
        end

        it 'shows the last 5 pages when showing the last page' do
          allow(mock_client).to receive(:search) do
            {
              'hits' => {
                'total' => 100,
                'hits' => []
              }
            }
          end

          query = Query.new('q' => 'foo', 'page' => '10')
          query.get_results(mock_client)

          expect(query.page_window).to eq([6, 7, 8, 9, 10])
        end

        it 'shows the last 5 pages on the second to last page' do
          allow(mock_client).to receive(:search) do
            {
              'hits' => {
                'total' => 100,
                'hits' => []
              }
            }
          end

          query = Query.new('q' => 'foo', 'page' => '9')
          query.get_results(mock_client)

          expect(query.page_window).to eq([6, 7, 8, 9, 10])
        end
      end
    end
  end
end
