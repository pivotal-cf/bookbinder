class UsageMessage
  def initialize(logger, commands, flags)
    @logger = logger
    @commands = commands
    @flags = flags
  end

  def print
    log_usage_header
    log_flag_usage_messages
    log_command_usage_messages
    0
  end

  def command(command_class)
    "bookbinder #{command_class.name.split('::').last.underscore} #{command_class.usage}"
  end

  private

  def log_flag_usage_messages
    @flags.each { |f| @logger.log "  bookbinder --#{f}" }
  end

  def log_command_usage_messages
    @commands.values.sort_by { |k| k.name }.each do |command_class|
      @logger.log "  #{command(command_class)}"
    end
  end

  def log_usage_header
    @logger.log <<TEXT

Bookbinder documentation can be found at https://github.com/pivotal-cf/docs-bookbinder

Usage (preface with 'bundle exec ' when using rbenv):
TEXT
  end
end
