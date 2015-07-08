require 'open3'

module Bookbinder
  class Sheller
    ShelloutFailure = Class.new(RuntimeError)

    class DevNull
      def puts(_)
      end

      def <<(_)
      end
    end

    def run_command(*command)
      out, err =
        if Hash === command.last
          command.last.values_at(:out, :err)
        else
          [DevNull.new, DevNull.new]
        end

      env_vars, executable =
        if Hash === command.first
          command[0..1]
        else
          [{}, command[0]]
        end

      exit_status = nil
      Open3.popen3(env_vars, executable) do |stdin, stdout, stderr, wait_thr|
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

    def get_stdout(command)
      out = StringIO.new
      run_command(command, out: out)
      out.tap(&:rewind).read.chomp
    end
  end
end
