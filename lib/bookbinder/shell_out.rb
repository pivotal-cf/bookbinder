require 'open3'

module ShellOut

  def shell_out(command, failure_okay = false)
    Open3.popen3(command) do |input, stdout, stderr, wait_thr|
      if wait_thr.value != 0
        contents_of_stderr = stderr.read
        error_message = contents_of_stderr.empty? ? stdout.read : contents_of_stderr
        raise "\n#{error_message}" unless failure_okay
      end
      stdout.read
    end
  end

end