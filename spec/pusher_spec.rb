require 'spec_helper'

describe Pusher, enable_pusher: true do
  include_context 'tmp_dirs'

  describe '#push' do
    context 'incorrectly logging in' do
      let(:app_dir) { tmp_subdir "some_dir" }

      before do
        Open4.stub(:popen4).and_return(double 'status', success?: false)
      end

      it 'raises an error and does not deploy' do
        expect(Open4).not_to receive(:popen4).with(/start/)
        expect(Open4).not_to receive(:popen4).with(/push/)
        expect(Open4).not_to receive(:popen4).with(/map-route/)

        expect {
          Pusher.new.push("", "", "", "", "", app_dir)
        }.to raise_error(/Could not log in/)
      end
    end
  end
end
