require 'yaml'
require 'tempfile'

module Bookbinder
  class RemoteYamlCredentialProvider
    def initialize(logger, repository, git_accessor = Git)
      @logger = logger
      @repository = repository
      @git_accessor = git_accessor
    end

    def credentials
      @logger.log "Processing #{@repository.full_name.cyan}"
      Dir.mktmpdir do |destination_dir|
        @repository.copy_from_remote(destination_dir, @git_accessor)
        cred_file_yaml = File.join(destination_dir, @repository.short_name, 'credentials.yml')
        YAML.load_file(cred_file_yaml)
      end
    end
  end
end
