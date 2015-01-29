require_relative '../../../../lib/bookbinder/commands/help'

module Bookbinder
  module Commands
    describe Help do
      it "has a special command name" do
        help = Help.new(unused_logger = nil)
        expect(help.command_for?('--help')).to be_truthy
      end
    end
  end
end
