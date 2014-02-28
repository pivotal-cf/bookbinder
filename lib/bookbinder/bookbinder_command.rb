class Cli
  class BookbinderCommand
    attr_accessor :config
    include BookbinderLogger

    def initialize(configuration)
      @config = configuration
    end

    def self.usage_message
      "bookbinder #{self.class.name.split('::').last.underscore} #{usage}"
    end

    def self.usage
      ""
    end
  end
end
