require_relative '../../../../template_app/lib/search/result'

module Bookbinder::Search
  describe Result do
    describe 'page_window' do
      it 'shows a single page' do
        result = Bookbinder::Search::Result.new('', 10, [], 1)

        expect(result.page_window).to eq([1])
      end

      it 'shows the first 5 pages' do
        result = Bookbinder::Search::Result.new('', 100, [], 1)

        expect(result.page_window).to eq([1, 2, 3, 4, 5])
      end

      it 'shows the 5 surrounding pages' do
        result = Bookbinder::Search::Result.new('', 100, [], 5)

        expect(result.page_window).to eq([3, 4, 5, 6, 7])
      end

      it 'shows the last 5 pages on the last page' do
        result = Bookbinder::Search::Result.new('', 100, [], 10)

        expect(result.page_window).to eq([6, 7, 8, 9, 10])
      end

      it 'shows the last 5 pages on the second to last page' do
        result = Bookbinder::Search::Result.new('', 100, [], 9)

        expect(result.page_window).to eq([6, 7, 8, 9, 10])
      end
    end
  end
end
