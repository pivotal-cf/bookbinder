require_relative '../../../../lib/bookbinder/commands/help'

module Bookbinder
  module Commands
    describe Help do
      it "has a special command name" do
        help = Help.new(unused_logger = nil, commands = [])
        expect(help.command_for?('--help')).to be_truthy
      end

      it "constructs its message from the other commands passed in" do
        commands = [
          double(usage: '--version something something', flag?: true),
          double(usage: '--anotherflag something something', flag?: true),
          double(usage: 'bind something something', flag?: false),
        ]
        help = Help.new(unused_logger = nil, commands)

        expect(help.usage_message).
          to match(/--version.+--anotherflag.+--help.+bind/m)
      end
    end
  end
end
