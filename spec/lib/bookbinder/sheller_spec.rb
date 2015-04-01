require_relative '../../../lib/bookbinder/sheller'

module Bookbinder
  describe Sheller do

    it 'redirects stdout to a log' do
      view_updater = double('view_updater', log: nil)
      sheller = Sheller.new(view_updater)

      expect(view_updater).to receive(:log).with("hello\n")

      sheller.run_command("echo 'hello'")
    end

    it 'redirects stderr to a log' do
      view_updater = double('view_updater', log: nil)
      sheller = Sheller.new(view_updater)

      expect(view_updater).to receive(:error).with("hello\n")

      sheller.run_command(">&2 echo hello")
    end

    it 'interleaves stdout and stderr' do
      view_updater = Class.new do
        attr_reader :output
        def initialize; @output = ""; end
        def log(line)
          @output << line
        end
        alias :error :log
      end.new

      sheller = Sheller.new(view_updater)
      sheller.run_command("echo first; sleep 0.01; >&2 echo second; sleep 0.01; >&1 echo third")
      expect(view_updater.output).to eq "first\nsecond\nthird\n"
    end

    it 'returns the exit status' do
      sheller = Sheller.new(double('view updater'))
      result = sheller.run_command("exit 1")
      expect(result).not_to be_success
    end
  end
end
