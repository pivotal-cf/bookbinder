require_relative '../../../lib/bookbinder/values/user_message'
require_relative '../../../lib/bookbinder/colorizer'
require_relative '../../../lib/bookbinder/terminal'
require_relative '../../helpers/redirection'
require_relative '../../helpers/matchers'

module Bookbinder
  describe Terminal do
    include Redirection

    context 'when the user message is an error' do
      let(:user_error_message) { UserMessage.new('error, error', EscalationType.error) }
      subject { capture_stderr { Terminal.new(Colorizer.new).update(user_error_message) } }
      it { should have_output('error, error').in_red }
    end

    context 'when the user message is a warning' do
      let(:user_error_message) { UserMessage.new('warning, Mr. Robinson', EscalationType.warn) }
      subject { capture_stdout { Terminal.new(Colorizer.new).update(user_error_message) } }
      it { should have_output('warning, Mr. Robinson').in_yellow }
    end
  end
end