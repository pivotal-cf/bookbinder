require 'spec_helper'

module Bookbinder
  describe Pusher, enable_pusher: true do
    include_context 'tmp_dirs'

    let(:cf) { double('command runner') }

    subject(:pusher) { Pusher.new(cf) }
    let(:app_dir) { tmp_subdir "pusher_spec" }

    def green
      BlueGreenApp.new('app-green')
    end

    def blue
      BlueGreenApp.new('app-blue')
    end

    describe 'when the hostname points to green' do
      before do
        expect(cf).to receive(:login).with(no_args).ordered
        allow(cf).to receive(:mapped_app_groups).with(no_args).and_return([[green]]).ordered
      end

      it 'starts the blue app, then remaps before taking the green app down' do
        expect(cf).to receive(:start).with(blue).ordered
        expect(cf).to receive(:push).with(blue).ordered
        expect(cf).to receive(:map_routes).with(blue).ordered
        expect(cf).to receive(:takedown_old_target_app).with(green).ordered

        pusher.push(app_dir)
      end
    end

    describe 'when the hostname points to blue' do
      before do
        expect(cf).to receive(:login).with(no_args).ordered
        allow(cf).to receive(:mapped_app_groups).with(no_args).and_return([[blue]]).ordered
      end

      it 'starts the green app, then remaps before taking the blue app down' do
        expect(cf).to receive(:start).with(green).ordered
        expect(cf).to receive(:push).with(green).ordered
        expect(cf).to receive(:map_routes).with(green).ordered
        expect(cf).to receive(:takedown_old_target_app).with(blue).ordered

        pusher.push(app_dir)
      end
    end

    describe 'when the hostname points to nothing (fresh install)' do
      let(:new_app) { BlueGreenApp.new('some-app-blue') }

      before do
        expect(cf).to receive(:login).with(no_args).ordered
        allow(cf).to receive(:mapped_app_groups).with(no_args).and_return([[]]).ordered
        allow(cf).to receive(:new_app).and_return(new_app)
      end

      it 'starts the blue app and maps it' do
        expect(cf).to receive(:push).with(new_app).ordered
        expect(cf).to receive(:map_routes).with(new_app).ordered

        pusher.push(app_dir)
      end
    end
  end
end
