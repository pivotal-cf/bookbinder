require_relative '../../../lib/bookbinder/terminal'
require_relative '../../../lib/bookbinder/command_validator'

module Bookbinder
  describe Terminal do
    context 'when the escalation type is of type error' do
      it 'updates the user interface with a message in red color' do
        colorizer = Colorizer.new
        terminal = Terminal.new(colorizer)
        user_message = CommandValidator::UserMessage.new('this is in red', EscalationType.error)

        begin
          real_stdout = $stdout
          $stdout = StringIO.new

          terminal.update(user_message)

          $stdout.rewind
          collected_output = $stdout.read

          expect(collected_output).to eq("\e[31mthis is in red\e[0m\n")

        ensure
          $stdout = real_stdout
        end
      end
    end
  end
end