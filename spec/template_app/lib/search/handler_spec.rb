require_relative '../../../../template_app/lib/search/handler'

module Bookbinder::Search
  describe Handler do
    describe '#call' do
      let(:mock_client) { double(:elastic_search) }
      let(:mock_client_class) { double(:elastic_search_class, new: mock_client) }
      let(:mock_services) do
        {
          searchly: [{
            credentials: {
              sslUri: 'foo.com'
            }
          }]
        }
      end
      let(:handler) { Handler.new(mock_client_class, {'VCAP_SERVICES' => JSON.dump(mock_services)}) }

      before do
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(end_with('public/search.html')) { '<%= yield %>' }
      end

      it 'renders the first page' do
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

        result = handler.call('QUERY_STRING' => 'q=foobar')
        html = result.last.first

        expect(html).to include('Hi')
        expect(html).to include('Im a highlight')

        expect(html).to include('Bye')
        expect(html).to include('Im bye highlight')

        expect(html).to include('Another')
        expect(html).to include('Im another highlight')

        expect(html).to include('1 to 3 of 3')
      end

      it 'properly escapes user input (product name and version)' do
        allow(mock_client).to receive(:search) do
          {
            'hits' => {
              'total' => 1,
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
              ]
            }
          }
        end

        result = handler.call('QUERY_STRING' => 'q=%3Cscript%3Ealert%28%22hi%22%29%3B%3C/script%3E&product_name=product_name=%3Cscript%3Ealert%28%22hi%22%29%3B%3C/script%3E&product_version=product_name=%3Cscript%3Ealert%28%22hi%22%29%3B%3C/script%3E')
        html = result.last.first

        expect(html).not_to include('<script>')
      end

      it 'renders the search page with a warning message' do
        handler = Handler.new(mock_client_class, {})
        result = handler.call('QUERY_STRING' => 'q=%3Cunconfigured_search%3E&')
        html = result.last.first

        expect(html).to include('Search is currently disabled. Please try again later')
      end

    end

    describe '#extract_query_params' do
      it 'extracts all the query params' do
        handler = Handler.new

        expect(handler.extract_query_params('foo=bar&baz=quux&jibber=jabber')).to eq({
          'foo' => 'bar',
          'baz' => 'quux',
          'jibber' => 'jabber'
        })
      end

      it 'extracts no query params' do
        handler = Handler.new

        expect(handler.extract_query_params('')).to eq({})
        expect(handler.extract_query_params(nil)).to eq({})
      end

      it 'extracts a query param with no value' do
        handler = Handler.new

        expect(handler.extract_query_params('foo=')).to eq({ 'foo' => '' })
      end

      it 'has an empty string for an unknown query param' do
        handler = Handler.new

        params = handler.extract_query_params('')
        expect(params['foo']).to eq('')
      end

      it 'escapes the space between search terms properly' do
        handler = Handler.new

        expect(handler.extract_query_params('q=foo+bar%20baz%2Bquux')).to eq({ 'q' => 'foo bar baz+quux'})
      end
    end

    describe '#extract_elasticsearch_url' do
      it 'gets a searchly provided url' do
        handler = Handler.new

        url = handler.extract_elasticsearch_url({ 'searchly' => [{'credentials' => {'sslUri' => 'https://searchly.example.com'}}] })
        expect(url).to eq('https://searchly.example.com')
      end

      it 'gets a user provided url' do
        handler = Handler.new

        url = handler.extract_elasticsearch_url({ 'user-provided' => [
            {'name' => 'things', 'credentials' => {'sslUri' => 'https://things.example.com'}},
            {'name' => 'elastic.co', 'credentials' => {'sslUri' => 'https://elastic.example.com'}},
            {'name' => 'stuff', 'credentials' => {'sslUri' => 'https://stuff.example.com'}}
        ] })
        expect(url).to eq('https://elastic.example.com')
      end

      it 'prefers user provided elastic search over searchly' do
        handler = Handler.new

        url = handler.extract_elasticsearch_url({
            'searchly' => [
                {'credentials' => {'sslUri' => 'https://searchly.example.com'}}
            ],
            'user-provided' => [
                {'name' => 'elastic.co', 'credentials' => {'sslUri' => 'https://elastic.example.com'}}
            ]
        })

        expect(url).to eq('https://elastic.example.com')
      end

      it 'uses searchly if no user provided service is for elastic search' do
        handler = Handler.new

        url = handler.extract_elasticsearch_url({
          'searchly' => [
              {'credentials' => {'sslUri' => 'https://searchly.example.com'}}
          ],
          'user-provided' => [
              {'name' => 'skipme', 'credentials' => {'sslUri' => 'https://elastic.example.com'}}
          ]
        })

        expect(url).to eq('https://searchly.example.com')
      end

      it 'returns nil when no elastic search is bound' do
        handler = Handler.new

        expect(handler.extract_elasticsearch_url({})).to be_nil
      end
    end
  end
end
