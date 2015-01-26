require_relative 'shell_out'

module Bookbinder
  class Sheller
    include ShellOut

    def run_command(command, failure_okay = false)
      shell_out(command, failure_okay)
    end
  end
end
