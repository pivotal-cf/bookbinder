class Cli
  class BookbinderCommand
    include BookbinderLogger

    def config
      @config ||= YAML.load(File.read('./config.yml'))
      raise 'config.yml is empty' unless @config
      @config
    end

    def usage_message
      "bookbinder #{self.class.name.split('::').last.underscore} #{usage}"
    end

    def usage
      ""
    end
  end
end
