class String
  include ANSI::Mixin
end

module BookbinderLogger

  def self.log(message)
    puts message
  end

  def log(message)
    BookbinderLogger.log message
  end

end