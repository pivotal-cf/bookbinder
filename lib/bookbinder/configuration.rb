require_relative 'remote_yaml_credential_provider'
require_relative 'git_hub_repository'

module Bookbinder
  class Configuration

    CURRENT_SCHEMA_VERSION = '1.0.0'
    STARTING_SCHEMA_VERSION = '1.0.0'

    class CredentialKeyError < StandardError;
    end

    class ConfigSchemaUnsupportedError < StandardError;
    end

    class AwsCredentials
      REQUIRED_KEYS = %w(access_key secret_key green_builds_bucket).freeze

      def initialize(cred_hash)
        @creds = cred_hash
      end

      REQUIRED_KEYS.each do |method_name|
        define_method(method_name) do
          begin
            creds.fetch(method_name)
          rescue KeyError => e
            raise CredentialKeyError, e
          end
        end
      end

      private

      attr_reader :creds
    end

    class CfCredentials
      REQUIRED_KEYS = %w(api_endpoint organization app_name).freeze
      OPTIONAL_KEYS = %w(username password production_space production_host staging_space staging_host).freeze

      def initialize(cred_hash, is_production)
        @creds = cred_hash
        @is_production = is_production
      end

      REQUIRED_KEYS.each do |method_name|
        define_method(method_name) do
          fetch(method_name)
        end
      end

      OPTIONAL_KEYS.each do |method_name|
        define_method(method_name) do
          creds.fetch(method_name, nil)
        end
      end

      def routes
        key = is_production ? 'production_host' : 'staging_host'
        fetch(key) if correctly_formatted_domain_and_routes?(key)
      end

      def flat_routes
        routes.reduce([]) do |all_routes, domain_apps|
          domain, apps = domain_apps
          all_routes + apps.map { |app| [domain, app] }
        end
      end

      def space
        key = is_production ? 'production_space' : 'staging_space'
        fetch(key)
      end

      private

      attr_reader :creds, :is_production

      def fetch(key)
        creds.fetch(key)
      rescue KeyError => e
        raise CredentialKeyError, e
      end

      def correctly_formatted_domain_and_routes?(deploy_environment)
        routes_hash = fetch(deploy_environment)
        domains = routes_hash.keys
        domains.each { |domain| correctly_formatted_domain?(domain, routes_hash) }
      end

      def correctly_formatted_domain?(domain, routes_hash)
        raise 'Each domain in credentials must be a single string.' unless domain.is_a? String
        raise "Domain #{domain} in credentials must contain a web extension, e.g. '.com'." unless domain.include?('.')
        raise "Did you mean to add a list of hosts for domain #{domain}? Check your credentials.yml." unless routes_hash[domain]
        raise "Hosts in credentials must be nested as an array under the desired domain #{domain}." unless routes_hash[domain].is_a? Array
        raise "Did you mean to provide a hostname for the domain #{domain}? Check your credentials.yml." if routes_hash[domain].any?(&:nil?)
      end
    end

    attr_reader :schema_version, :schema_major_version, :schema_minor_version, :schema_patch_version

    def initialize(logger, config_hash)
      @logger = logger
      @config = config_hash
    end

    CONFIG_REQUIRED_KEYS = %w(book_repo layout_repo cred_repo sections public_host pdf pdf_index versions)
    CONFIG_OPTIONAL_KEYS = %w(archive_menu)

    CONFIG_REQUIRED_KEYS.each do |method_name|
      define_method(method_name) do
        config.fetch(method_name)
      end
    end

    CONFIG_OPTIONAL_KEYS.each do |method_name|
      define_method(method_name) do
        config[method_name]
      end
    end

    def has_option?(key)
      @config.has_key?(key)
    end

    def template_variables
      config.fetch('template_variables', {})
    end

    def aws_credentials
      @aws_creds ||= AwsCredentials.new(credentials.fetch('aws'))
    end

    def cf_staging_credentials
      @cf_staging_creds ||= CfCredentials.new(credentials.fetch('cloud_foundry'), false)
    end

    def cf_production_credentials
      @cf_prod_creds ||= CfCredentials.new(credentials.fetch('cloud_foundry'), true)
    end

    def ==(o)
      (o.class == self.class) && (o.config == self.config)
    end

    alias_method :eql?, :==

    protected

    attr_reader :config

    private

    def credentials
      @credentials ||= RemoteYamlCredentialProvider.new(@logger, credentials_repository).credentials
    end

    def credentials_repository
      @credentials_repository ||= GitHubRepository.new(logger: @logger, full_name: cred_repo)
    end
  end
end
