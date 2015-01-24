require_relative 'shell_out'

module Bookbinder
  include ShellOut

  class Shell
    def run_command(command, failure_okay = false)
      shell_out(command, failure_okay)
    end
  end
end
