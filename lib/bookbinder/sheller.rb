require 'open3'

module Bookbinder
  class Sheller
    ShelloutFailure = Class.new(RuntimeError)

    class DevNull
      def puts(_)
      end
    end

    def run_command(command, out: DevNull.new, err: DevNull.new)
      exit_status = nil
      Open3.popen3(command) do |stdin, stdout, stderr, wait_thr|
        t = Thread.new do
          stdout.each do |line|
            out.puts(line)
          end
        end
        stderr.each do |line|
          err.puts(line)
        end
        t.join
        exit_status = wait_thr.value
      end
      exit_status
    end

    attr_reader :view_updater
  end
end
