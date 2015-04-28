require 'git'
require_relative 'git_hub_repository'
require_relative 'remote_yaml_credential_provider'

module Bookbinder
  class Configuration

    CURRENT_SCHEMA_VERSION = '1.0.0'
    STARTING_SCHEMA_VERSION = '1.0.0'

    CredentialKeyError = Class.new(RuntimeError)
    ConfigSchemaUnsupportedError = Class.new(RuntimeError)

    attr_reader :schema_version, :schema_major_version, :schema_minor_version, :schema_patch_version

    def initialize(logger, config_hash)
      @logger = logger
      @config = config_hash
    end

    CONFIG_REQUIRED_KEYS = %w(book_repo public_host)
    CONFIG_OPTIONAL_KEYS = %w(archive_menu layout_repo versions cred_repo)

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

    def sections
      config.fetch('sections', [])
    end

    def dita_sections
      config.fetch('dita_sections', {})
    end

    def has_option?(key)
      @config.has_key?(key)
    end

    def template_variables
      config.fetch('template_variables', {})
    end

    def aws_credentials
      @aws_creds ||= AwsCredentials.new(credentials.fetch('aws', {}))
    end

    def cf_credentials(environment)
      CfCredentials.new(credentials.fetch('cloud_foundry', {}), environment)
    end

    def ==(o)
      o.class == self.class && o.instance_variable_get(:@config) == @config
    end

    alias_method :eql?, :==

    class AwsCredentials
      REQUIRED_KEYS = %w(access_key secret_key green_builds_bucket)

      def initialize(aws_cred_hash)
        @creds = aws_cred_hash
      end

      REQUIRED_KEYS.each do |method_name|
        define_method(method_name) do
          creds.send(:[], method_name)
        end
      end

      private

      attr_reader :creds
    end

    class CfCredentials
      REQUIRED_KEYS = %w(username password api_endpoint organization app_name)

      def initialize(cf_cred_hash, environment)
        @creds = cf_cred_hash
        @environment = environment
      end

      REQUIRED_KEYS.each do |method_name|
        define_method(method_name) do
          creds.send(:[], method_name)
        end
      end

      def ==(other)
        [@creds, @environment] == [
          other.instance_variable_get(:@creds),
          other.instance_variable_get(:@environment)
        ]
      end

      def download_archive_before_push?
        production?
      end

      def push_warning
        if production?
          'Warning: You are pushing to CF Docs production. Be careful.'
        end
      end

      def routes
        fetch(host_key) if correctly_formatted_domain_and_routes?(host_key)
      end

      def flat_routes
        routes.reduce([]) do |all_routes, domain_apps|
          domain, apps = domain_apps
          all_routes + apps.map { |app| [domain, app] }
        end
      end

      def space
        fetch(space_key)
      end

      private

      attr_reader :creds, :environment

      def production?
        environment == 'production'
      end

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

      def host_key
        "#{environment}_host"
      end

      def space_key
        "#{environment}_space"
      end
    end

    private

    attr_reader :config

    def credentials
      @credentials ||= RemoteYamlCredentialProvider.new(@logger, credentials_repository).credentials
    end

    def credentials_repository
      @credentials_repository ||= GitHubRepository.new(logger: @logger, full_name: cred_repo, git_accessor: Git)
    end
  end
end
