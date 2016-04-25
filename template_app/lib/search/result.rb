require_relative 'hit'

module Bookbinder
  module Search
    class Result
      def initialize(query, hit_count, raw_hits, page_number)
        @query = query
        @hit_count = hit_count
        @hits = raw_hits.map { |h| Hit.new(h) }
        @page_number = page_number
        @last_page = (hit_count / 10.0).ceil
        @page_window = calculate_page_window
      end

      attr_reader :query, :hit_count, :hits, :page_number, :last_page, :page_window

      private

      def calculate_page_window
        window_start = [page_number - 2, 1].max
        window_end = [window_start + 4, last_page].min
        window = (window_start .. window_end).to_a

        if window.length < 5 && window.last == last_page && window.first != 1
          window.unshift(window.first - 1)
          if window.length < 5
            window.unshift(window.first - 1)
          end
        end

        window
      end
    end
  end
end
