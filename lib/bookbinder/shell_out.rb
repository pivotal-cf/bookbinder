require 'open3'

module Bookbinder
  module ShellOut
    def shell_out(command, failure_okay = false)
      Open3.popen3(command) do |input, stdout, stderr, wait_thr|
        command_failed = (wait_thr.value != 0)
        announce_failure(failure_okay, stderr, stdout) if command_failed
        stdout.read
      end
    end

    def announce_failure(failure_okay, stderr, stdout)
      contents_of_stderr = stderr.read
      error_message = contents_of_stderr.empty? ? stdout.read : contents_of_stderr
      raise "\n#{error_message}" unless failure_okay
    end
  end
end
