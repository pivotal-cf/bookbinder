class Cli
  class BookbinderCommand
    def config
      @config ||= YAML.load(File.read('./config.yml'))
    end

    def usage_message
      "bookbinder #{self.class.name.split('::').last.underscore} #{usage}"
    end

    def usage
      ""
    end
  end
end