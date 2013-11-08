require 'spec_helper'

describe ShellOut do

  describe 'shell_out' do

    include ShellOut

    it 'returns the stdout' do
      stdout = shell_out("echo 'hi'")
      stdout.should include('hi')
    end

    it 'raises an error with stderr in the message if a non-zero exit status was returned' do
      expect {shell_out('blah blah')}.to raise_error(/No such file or directory - blah/)
    end

    it 'raises an error with stdout in the mesasge if the command returned a non-zero exit code and had empty stderr' do
      expect {shell_out('ruby spec/fixtures/script.rb')}.to raise_error(/This is stdout/)
    end
  end
end