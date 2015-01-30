require_relative '../../../lib/bookbinder/command_validator'

module Bookbinder
  describe CommandValidator do
    context 'when the command is not recognized' do
      it 'returns a user message of error escalation' do
        commands = [double('command', command_for?: false)]
        command_validator = CommandValidator.new(commands, 'usage_message')

        validation_result = command_validator.validate!('not_a_valid_command')

        expect(validation_result.escalation_type).to eq(EscalationType.error)
      end
    end
  end

end
