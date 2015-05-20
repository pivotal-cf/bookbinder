module Bookbinder
  class TimeFetcher
    def current_time
      Time.now.strftime("%Y%m%d_%H%M")
    end
  end
end