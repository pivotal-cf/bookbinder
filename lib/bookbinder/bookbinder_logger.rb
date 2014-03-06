class String
  include ANSI::Mixin
end

module BookbinderLogger

  def self.log(message)
    puts message
  end

  def self.log_print(message)
    print message
  end

  def log(message)
    BookbinderLogger.log message
  end

  def log_print(message)
    BookbinderLogger.log_print message
  end

end
