module Bookbinder
  class UsageMessenger

    def construct_for commands, flags
      log_usage_header + "\n" + flag_usage_messages(flags) + command_usage_messages(commands)
    end

    private

    def flag_usage_messages(flags)
      flag_usage_messages = ""
      flags.each { |f| flag_usage_messages += " \t#{f.usage}\n" }
      flag_usage_messages
    end

    def command_usage_messages(commands)
      flag_command_messages = ""
      commands.each do |command_class|
        flag_command_messages += " \t#{command_class.usage}\n"
      end
      flag_command_messages
    end

    def log_usage_header
      <<TEXT

  \e[1;39;49mDocumentation\e[0m: https://github.com/pivotal-cf/docs-bookbinder

  \e[1;39;49mUsage\e[0m: bookbinder <command|flag> [args]
TEXT
    end
  end
end
