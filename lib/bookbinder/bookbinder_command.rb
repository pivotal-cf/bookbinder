class Cli
  class BookbinderCommand
    include BookbinderLogger

    def initialize(configuration)
      @config = configuration
    end

    private
    attr_accessor :config
  end
end
