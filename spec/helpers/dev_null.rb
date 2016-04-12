module DevNull
  class Stream
    def puts(*args)
    end

    def <<(*args)
    end
  end

  def self.get_streams
    {
      out: Stream.new,
      err: Stream.new,
      success: Stream.new,
      warn: Stream.new
    }
  end
end
