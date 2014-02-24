class Cli
  class CredentialKeyError < KeyError
  end

  module CommandRequiringCredentials
    def config
      @config ||= YAML.load(File.read('./config.yml'))
      raise 'config.yml is empty' unless @config
      @config.merge(credentials)
    end

    private

    def credentials
      if @config['cred_repo']
        repo = CredRepo.new full_name: @config['cred_repo']
        repo.credentials
      else
        {}
      end
    end
  end
end
