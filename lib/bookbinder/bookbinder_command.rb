class Cli
  class BookbinderCommand
    include BookbinderLogger

    def initialize(configuration)
      @config = configuration
    end

    def self.usage
      ""
    end

    private
    attr_accessor :config
  end
end
