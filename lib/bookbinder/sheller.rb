require 'open3'

module Bookbinder
  class Sheller
    ShelloutFailure = Class.new(RuntimeError)

    def initialize(view_updater)
      @view_updater = view_updater
    end

    def run_command(command)
      exit_status = nil
      Open3.popen3(command) do |stdin, stdout, stderr, wait_thr|
        stdout.each do |line|
          view_updater.log(line)
        end
        stderr.each do |line|
          view_updater.error(line)
        end
        exit_status = wait_thr.value
      end

      unless exit_status.success?
        raise ShelloutFailure.new "Shelling out failed."
      end
    end

    attr_reader :view_updater
  end
end
