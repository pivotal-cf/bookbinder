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

    def initialize(logger, config_hash, bookbinder_schema_version=CURRENT_SCHEMA_VERSION)
      @logger = logger
      @config = config_hash
      @schema_version = bookbinder_schema_version
      @schema_major_version, @schema_minor_version, @schema_patch_version = bookbinder_schema_version.split('.')

      if user_schema_version.nil?
        raise Configuration::ConfigSchemaUnsupportedError.new schema_now_required_message unless @schema_version == STARTING_SCHEMA_VERSION
      elsif user_major_version > @schema_major_version
        raise Configuration::ConfigSchemaUnsupportedError.new unrecognized_schema_version_message
      elsif user_minor_version > @schema_minor_version
        raise Configuration::ConfigSchemaUnsupportedError.new unrecognized_schema_version_message
      elsif user_patch_version > @schema_patch_version
        raise Configuration::ConfigSchemaUnsupportedError.new unrecognized_schema_version_message
      elsif user_major_version < @schema_major_version
        raise Configuration::ConfigSchemaUnsupportedError.new incompatible_schema_message
      elsif user_minor_version < @schema_minor_version
        @logger.warn nonbreaking_schema_message_for("minor")
      elsif user_patch_version < @schema_patch_version
        @logger.warn nonbreaking_schema_message_for("patch")
      end

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

    def valid?
      directory_names = @config['sections'].map {|section| section['directory']}
      directory_names.length == directory_names.uniq.length
    end

    def ==(o)
      (o.class == self.class) && (o.config == self.config)
    end

    alias_method :eql?, :==

    protected

    attr_reader :config

    private

    def user_schema_version
      @config['schema_version']
    end

    def user_major_version
      user_schema_version.split('.').first
    end

    def user_minor_version
      user_schema_version.split('.')[1]
    end

    def user_patch_version
      user_schema_version.split('.').last
    end

    def schema_now_required_message
      "[ERROR] Bookbinder now requires a certain schema. Please see README and provide a schema version."
    end

    def incompatible_schema_message
      "[ERROR] Your config.yml format, schema version #{user_schema_version}, is older than this version of Bookbinder can support. Please update your config.yml keys and format to version #{@schema_version} and try again."
    end

    def unrecognized_schema_version_message
      "[ERROR] The config schema version #{user_schema_version} is unrecognized by this version of Bookbinder. The latest schema version is #{@schema_version}."
    end

    def nonbreaking_schema_message_for(version_level)
      "[WARNING] Your schema is valid, but there exists a new #{version_level} version. Consider updating your config.yml."
    end

    def credentials
      @credentials ||= CredentialProvider.new(@logger, credentials_repository).credentials
    end

    def credentials_repository
      @credentials_repository ||= Repository.new(logger: @logger, full_name: cred_repo)
    end
  end
end