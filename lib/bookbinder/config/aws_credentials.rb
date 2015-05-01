module Bookbinder
  module Config
    class AwsCredentials
      REQUIRED_KEYS = %w(access_key secret_key green_builds_bucket)

      def initialize(aws_cred_hash)
        @creds = aws_cred_hash
      end

      REQUIRED_KEYS.each do |method_name|
        define_method(method_name) do
          creds[method_name]
        end
      end

      private

      attr_reader :creds
    end
  end
end
