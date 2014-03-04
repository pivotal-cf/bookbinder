class Configuration
  def initialize(config)
    @config = config.symbolize_keys
  end

  def method_missing(method, *args, &block)
    config.fetch(method)
  end

  def aws_credentials
    Configuration.new(credentials.aws)
  end

  def cf_credentials
    Configuration.new(credentials.cloud_foundry)
  end

  def ==(o)
    (o.class == self.class) && (o.config == self.config)
  end

  def respond_to?(method, include_private = false)
    methods = config.keys + [:aws_credentials, :cf_credentials]
    methods << :credentials if include_private
    methods.include?(method)
  end

  alias_method :eql?, :==

  protected

  def config
    @config
  end

  private

  def credentials
    @credentials ||= Configuration.new(CredRepo.new(full_name: self.cred_repo).credentials)
  end
end
