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
          double(usage: ['--version', 'You can probably guess'], flag?: true),
          double(usage: ['--anotherflag', 'Something wild'], flag?: true),
          double(usage: ["bind <local|github> [--verbose] [--dita-flags='<dita-option>=<value>']", 'Bind a booky wooky'], flag?: false),
        ]
        help = Help.new(unused_logger = nil, commands)

        expect(help.usage_message).
          to eq(<<-MSG)

  \e[1;39;49mDocumentation\e[0m: https://github.com/pivotal-cf/docs-bookbinder

  \e[1;39;49mUsage\e[0m: bookbinder <command|flag> [args]

    --version                                                               You can probably guess
    --anotherflag                                                           Something wild
    --help                                                                  Print this message
    bind <local|github> [--verbose] [--dita-flags='<dita-option>=<value>']  Bind a booky wooky
        MSG
      end
    end
  end
end
