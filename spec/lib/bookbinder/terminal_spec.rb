require_relative '../../../lib/bookbinder/terminal'
require_relative '../../../lib/bookbinder/command_validator'

module Bookbinder
  describe Terminal do
    context 'when the escalation type is of type error' do
      it 'updates the user interface with a message in red color' do
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
end