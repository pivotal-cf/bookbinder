require_relative '../../../../template_app/lib/search/handler'

module Bookbinder::Search
  describe Handler do
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

        expect(handler.extract_query_params('foo=')).to eq({ 'foo' => nil })
      end
    end
  end
end
