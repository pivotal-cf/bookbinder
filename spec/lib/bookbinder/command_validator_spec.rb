require_relative '../../../lib/bookbinder/command_validator'

module Bookbinder
  describe CommandValidator do
    UNTESTED_USAGE = nil

    context 'when the command is not recognized' do
      it 'returns a user message of error escalation' do
        commands = [double('command', command_for?: false)]
        command_validator = CommandValidator.new(commands, UNTESTED_USAGE)

        validation_result = command_validator.validate('not_a_valid_command')

        expect(validation_result.escalation_type).to eq(EscalationType.error)
      end

      it 'includes the passed usage text in the message' do
        validator = CommandValidator.new([double(command_for?: false)],
                                         'my usage message')
        result = validator.validate('not_a_valid_command')
        expect(result.message).to match(/my usage message$/)
      end

      it 'identifies it as a "flag" if it starts with --' do
        command_validator = CommandValidator.new([], UNTESTED_USAGE)
        result = command_validator.validate('--foo')
        expect(result.message).to match(/^Unrecognized flag/)
      end

      it 'identifies it as a "command" if it starts with any other char' do
        command_validator = CommandValidator.new([], UNTESTED_USAGE)
        result = command_validator.validate('^foo')
        expect(result.message).to match(/^Unrecognized command/)
      end
    end

    context 'when the command is deprecated' do
      it 'returns a user message of warning escalation' do
        commands = [double('deprecated_command',
                           command_for?: true,
                           deprecated_command_for?: true,
                           usage: []
                    )]
        command_validator = CommandValidator.new(commands, UNTESTED_USAGE)
        validation_result = command_validator.validate('deprecated_command')

        expect(validation_result.escalation_type).to eq(EscalationType.warn)
      end

      it 'returns a user message of deprecation' do
        deprecated_command = double('deprecated_command',
                                     command_for?: true,
                                     usage: [])
        commands = [deprecated_command]

        allow(deprecated_command).to receive(:deprecated_command_for?).with('deprecated_command').and_return true

        command_validator = CommandValidator.new(commands, UNTESTED_USAGE)
        validation_result = command_validator.validate('deprecated_command')

        expect(validation_result.message).to match(/Use of deprecated_command is deprecated./)
      end

      it 'returns a user message containing the preferred usage' do
        deprecated_command = double('deprecated_command',
                                    command_for?: true,
                                    usage: ['this is what you type', 'this is the description'])
        commands = [deprecated_command]

        allow(deprecated_command).to receive(:deprecated_command_for?).
          with('deprecated_command').
          and_return true

        command_validator = CommandValidator.new(commands, UNTESTED_USAGE)
        validation_result = command_validator.validate('deprecated_command')

        expect(validation_result.message).to match(/this is what you type/)
      end
    end

    context 'when the command is not deprecated, and does not define the method' do
      it 'passes validation' do
        validator = CommandValidator.new([double(command_for?: true)],
                                         UNTESTED_USAGE)
        result = validator.validate('currentcommand')
        expect(result.escalation_type).to eq(EscalationType.success)
      end
    end
  end
end
