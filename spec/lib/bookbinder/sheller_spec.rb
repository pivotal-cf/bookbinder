require_relative '../../../lib/bookbinder/sheller'

module Bookbinder
  describe Sheller do

    it 'prints to standard out' do
      view_updater = double('view_updater', log: nil)
      sheller = Sheller.new(view_updater)

      expect(view_updater).to receive(:log).with("hello\n")

      sheller.run_command("echo 'hello'")
    end

    context 'when the command exits with 1' do
      it 'raises' do
        view_updater = double('view_updater', log: nil)
        sheller = Sheller.new(view_updater)
        expect { sheller.run_command("exit 1") }.to raise_error Sheller::ShelloutFailure
      end
    end
  end
end