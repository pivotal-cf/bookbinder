require_relative '../../../lib/bookbinder/terminal'

module Bookbinder
  describe Terminal do
    it 'updates the user interface with a message' do
      terminal = Terminal.new

      begin
        real_stdout = $stdout
        $stdout = StringIO.new

        terminal.update('user_message')

        $stdout.rewind
        collected_output = $stdout.read

        expect(collected_output).to eq("user_message\n")

      ensure
        $stdout = real_stdout
      end
    end
  end
end