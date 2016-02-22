module Bookbinder
  module Config
    class CfCredentials
      REQUIRED_KEYS = %w(username password api_endpoint organization app_name)
      CredentialKeyError = Class.new(RuntimeError)

      def initialize(cf_cred_hash, environment)
        @creds = cf_cred_hash
        @environment = environment
      end

      REQUIRED_KEYS.each do |method_name|
        define_method(method_name) do
          creds[method_name]
        end
      end

      def ==(other)
        [@creds, @environment] == [
          other.instance_variable_get(:@creds),
          other.instance_variable_get(:@environment)
        ]
      end

      def routes
        fetch('host') if correctly_formatted_domain_and_routes?
      end

      def flat_routes
        routes.flat_map { |(domain, apps)| apps.map { |app| [domain, app] } }
      end

      def space
        fetch('space')
      end

      private

      attr_reader :creds, :environment

      def fetch(key)
        creds.fetch('env').fetch(environment).fetch(key)
      rescue KeyError => e
        raise CredentialKeyError, e
      end

      def correctly_formatted_domain_and_routes?
        routes_hash = fetch('host')
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
  end
end
