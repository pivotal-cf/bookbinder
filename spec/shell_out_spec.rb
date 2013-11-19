require 'spec_helper'

describe ShellOut do

  describe 'shell_out' do

    include ShellOut

    it 'returns the stdout' do
      stdout = shell_out("echo 'hi'")
      stdout.should include('hi')
    end

    it 'raises an error with stderr in the message if a non-zero exit status was returned' do
      expect {shell_out('ruby spec/fixtures/failing_script_with_stderr.rb')}.to raise_error(/This is stderr/)
    end

    it 'raises an error with stdout in the mesasge if the command returned a non-zero exit code and had empty stderr' do
      expect {shell_out('ruby spec/fixtures/failing_script_with_no_stderr.rb')}.to raise_error(/This is stdout/)
    end

    it 'does not raise an error if the command returned a non-zero exit code and the no-error flag was passed' do
      expect {shell_out('ruby spec/fixtures/failing_script_with_stderr.rb', true)}.not_to raise_error
    end
  end
end