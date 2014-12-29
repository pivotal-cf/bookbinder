class UsageMessenger
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

  private

  def log_flag_usage_messages
    @flags.each { |f| @logger.log "  bookbinder --#{f}" }
  end

  def log_command_usage_messages
    @commands.values.sort_by(&:usage).each do |command_class|
      @logger.log "  bookbinder #{command_class.usage}"
    end
  end

  def log_usage_header
    @logger.log <<TEXT

Bookbinder documentation can be found at https://github.com/pivotal-cf/docs-bookbinder

Usage (preface with 'bundle exec ' when using rbenv):
TEXT
  end
end
