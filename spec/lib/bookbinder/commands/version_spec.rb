require_relative '../../../../lib/bookbinder/commands/version'

module Bookbinder
  module Commands
    describe Version do
      it "has a special command name" do
        version = Version.new(unused_logger = nil)
        expect(version.command_for?('--version')).to be_truthy
      end
    end
  end
end
