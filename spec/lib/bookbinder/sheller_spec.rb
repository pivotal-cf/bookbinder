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

    context 'when the command exits with 1' do
      it 'raises' do
        view_updater = double('view_updater', log: nil)
        sheller = Sheller.new(view_updater)
        expect { sheller.run_command("exit 1") }.to raise_error Sheller::ShelloutFailure
      end
    end
  end
end
