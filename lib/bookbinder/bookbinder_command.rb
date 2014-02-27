class Cli
  class BookbinderCommand
    include BookbinderLogger

    def run(*args)
      child_run(*args)
    rescue Cli::CredentialKeyError => e
      log "#{e.message}, in credentials.yml".red
      1
    rescue KeyError => e
      log "#{e.message}, in config.yml".red
      1
    rescue => e
      log e.message.red
      1
    end

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
