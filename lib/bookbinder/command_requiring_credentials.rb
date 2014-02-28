class Cli
  class CredentialKeyError < KeyError; end

  module CommandRequiringCredentials
    def config
      @config ||= YAML.load(File.read('./config.yml'))
      raise 'config.yml is empty' unless @config
      @config.merge(credentials)
    end

    private

    def credentials
      raise missing_repository_key unless @config['cred_repo']
      @credentials ||= CredRepo.new(full_name: @config['cred_repo']).credentials
    end

    def missing_repository_key
      'A credentials repository must be specified'
    end
  end
end
