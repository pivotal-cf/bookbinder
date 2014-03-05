class Cli
  class PushLocalToStaging < BookbinderCommand
    def run(_)
      cf_command_runner = CfCommandRunner.new(config.cf_staging_credentials)
      Pusher.new(cf_command_runner).push('./final_app')
      0
    rescue KeyError => e
      raise CredentialKeyError, e
    end

    def self.usage
      ''
    end
  end
end
