module Bookbinder
  class Sheller
    ShelloutFailure = Class.new(RuntimeError)

    def initialize(view_updater)
      @view_updater = view_updater
    end

    def run_command(command)
      IO.popen(command) do |stdout|
        stdout.each { |line| view_updater.log line }
      end

      raise ShelloutFailure.new "Shelling out failed." unless $?.success?
    end

    attr_reader :view_updater
  end
end
