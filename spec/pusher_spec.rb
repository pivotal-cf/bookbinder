require 'spec_helper'

module Bookbinder
  describe Pusher, enable_pusher: true do
    include_context 'tmp_dirs'

    let(:creds) do
      Configuration::CfCredentials.new(
          {
              'api_endpoint' => nil,
              'app_name' => 'app'
          },
          false
      )
    end

    let(:cf) do
      double(creds: creds)
    end

    subject(:pusher) { Pusher.new(cf) }
    let(:app_dir) { tmp_subdir "pusher_spec" }

    describe '#push' do
      describe 'when the hostname points to green' do
        before do
          expect(cf).to receive(:login).with(no_args).ordered
          expect(cf).to receive(:apps).with(no_args).and_return([['app-green']]).ordered
        end

        it 'makes the right CF calls' do
          expect(cf).to receive(:start).with('app-blue').ordered
          expect(cf).to receive(:push).with('app-blue').ordered
          expect(cf).to receive(:map_routes).with('app-blue').ordered
          expect(cf).to receive(:takedown_old_target_app).with('app-green').ordered

          pusher.push(app_dir)
        end
      end

      describe 'when the hostname points to blue' do
        before do
          expect(cf).to receive(:login).with(no_args).ordered
          expect(cf).to receive(:apps).with(no_args).and_return([['app-blue']]).ordered
        end

        it 'makes the right CF calls' do
          expect(cf).to receive(:start).with('app-green').ordered
          expect(cf).to receive(:push).with('app-green').ordered
          expect(cf).to receive(:map_routes).with('app-green').ordered
          expect(cf).to receive(:takedown_old_target_app).with('app-blue').ordered

          pusher.push(app_dir)
        end
      end
    end
  end
end
