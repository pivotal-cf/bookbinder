require 'yaml'
require 'tempfile'

module Bookbinder
  class RemoteYamlCredentialProvider
    def initialize(logger, repository)
      @logger = logger
      @repository = repository
    end

    def credentials
      @logger.log "Processing #{@repository.full_name.cyan}"
      Dir.mktmpdir do |destination_dir|
        @repository.copy_from_remote(destination_dir)
        cred_file_yaml = File.join(destination_dir, @repository.short_name, 'credentials.yml')
        YAML.load_file(cred_file_yaml)
      end
    end
  end
end
