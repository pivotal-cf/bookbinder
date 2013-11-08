require 'open3'

module ShellOut

  def shell_out(command)
    Open3.popen3(command) do |input, stdout, stderr, wait_thr|
      if wait_thr.value != 0
        contents_of_stderr = stderr.read
        error_message = contents_of_stderr.empty? ? stdout.read : contents_of_stderr
        raise "\n#{error_message}"
      end
      stdout.read
    end
  end

end