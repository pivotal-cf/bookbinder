require_relative '../../../lib/bookbinder/command_validator'

module Bookbinder
  describe CommandValidator do
    context 'when the command is not recognized' do
      it 'returns a user message of error escalation' do
        commands = [double('command', command_for?: false)]
        command_validator = CommandValidator.new(commands, 'usage_text')

        validation_result = command_validator.validate('not_a_valid_command')

        expect(validation_result.escalation_type).to eq(EscalationType.error)
      end
    end

    context 'when the command is deprecated' do
      it 'returns a user message of warning escalation' do
        commands = [double('deprecated_command',
                           command_for?: true,
                           deprecated_command_for?: true,
                           usage: true
                    )]
        command_validator = CommandValidator.new(commands, 'usage_text')
        validation_result = command_validator.validate('deprecated_command')

        expect(validation_result.escalation_type).to eq(EscalationType.warn)
      end

      it 'returns a user message of deprecation' do
        deprecated_command = double('deprecated_command',
                                     command_for?: true,
                                     usage: true)
        commands = [deprecated_command]

        allow(deprecated_command).to receive(:deprecated_command_for?).with('deprecated_command').and_return true

        command_validator = CommandValidator.new(commands, 'usage_text')
        validation_result = command_validator.validate('deprecated_command')

        expect(validation_result.message).to match(/Use of deprecated_command is deprecated./)
      end

      it 'returns a user message containing the preferred usage' do
        deprecated_command = double('deprecated_command',
                                    command_for?: true)
        commands = [deprecated_command]

        allow(deprecated_command).to receive(:deprecated_command_for?).with('deprecated_command').and_return true
        allow(deprecated_command).to receive(:usage).and_return('this is the preferred usage')

        command_validator = CommandValidator.new(commands, 'usage_text')
        validation_result = command_validator.validate('deprecated_command')

        expect(validation_result.message).to match(/this is the preferred usage/)
      end
    end
  end
end
