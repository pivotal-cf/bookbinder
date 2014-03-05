class Configuration
  class AwsCredentials
    REQUIRED_KEYS = %w(access_key secret_key green_builds_bucket).freeze

    def initialize(cred_hash)
      @creds = cred_hash
    end

    REQUIRED_KEYS.each do |method_name|
      define_method(method_name) do
        creds.fetch(method_name)
      end
    end

    private

    attr_reader :creds
  end

  class CfCredentials
    REQUIRED_KEYS = %w(api_endpoint staging_host organization staging_space app_name).freeze
    OPTIONAL_KEYS = %w(production_host production_space username password).freeze

    def initialize(cred_hash)
      @creds = cred_hash
    end

    REQUIRED_KEYS.each do |method_name|
      define_method(method_name) do
        creds.fetch(method_name)
      end
    end

    OPTIONAL_KEYS.each do |method_name|
      define_method(method_name) do
        creds.fetch(method_name, nil)
      end
    end

    private

    attr_reader :creds
  end

  def initialize(config_hash)
    @config = config_hash
  end

  %w(book_repo cred_repo repos public_host).each do |method_name|
    define_method(method_name) do
      config.fetch(method_name)
    end
  end

  def template_variables
    config.fetch('template_variables', {})
  end

  def aws_credentials
    AwsCredentials.new(credentials.fetch('aws'))
  end

  def cf_credentials
    CfCredentials.new(credentials.fetch('cloud_foundry'))
  end

  def ==(o)
    (o.class == self.class) && (o.config == self.config)
  end

  alias_method :eql?, :==

  protected

  attr_reader :config

  private

  def credentials
    @credentials ||= CredRepo.new(full_name: cred_repo).credentials
  end
end
