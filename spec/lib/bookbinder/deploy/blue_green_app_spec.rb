require_relative '../../../../lib/bookbinder/deploy/blue_green_app'

module Bookbinder
  module Deploy
    describe BlueGreenApp do
      it "can flip its name even when it starts with 'blue'" do
        expect(BlueGreenApp.new('blue-app-blue').with_flipped_name).
          to eq(BlueGreenApp.new('blue-app-green'))
      end

      it "can flip its name even when it starts with 'green'" do
        expect(BlueGreenApp.new('green-app-green').with_flipped_name).
          to eq(BlueGreenApp.new('green-app-blue'))
      end
    end
  end
end
