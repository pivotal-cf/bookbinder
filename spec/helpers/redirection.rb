module Bookbinder
  module Redirection
    def capture_stdout(&block)
      real_stdout = $stdout
      $stdout = StringIO.new
      block.call
      $stdout.rewind
      $stdout.read
    ensure
      $stdout = real_stdout
    end

    def capture_stderr(&block)
      real_stderr = $stderr
      $stderr = StringIO.new
      block.call
      $stderr.rewind
      $stderr.read
    ensure
      $stderr = real_stderr
    end

    def swallow_stdout(&block)
      real_stdout = $stdout
      $stdout = StringIO.new
      block.call
    ensure
      $stdout = real_stdout
    end

    def swallow_stderr(&block)
      real_stderr = $stderr
      $stderr = StringIO.new
      block.call
    ensure
      $stderr = real_stderr
    end
  end
end
