module Bookbinder
  class TimeFetcher
    def fetch
      Time.now.strftime("%Y%m%d_%H%M")
    end
  end
end