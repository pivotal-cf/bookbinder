require 'yaml'

module Bookbinder
  module Config
    FileNotFoundError = Class.new(RuntimeError)
    InvalidSyntaxError = Class.new(RuntimeError)

    class YAMLLoader
      def load(path)
        if File.exist?(path)
          config(path)
        else
          raise FileNotFoundError.new, "YAML"
        end
      rescue Psych::SyntaxError => e
        raise InvalidSyntaxError.new e
      end

      def load_key(path, key)
        if File.exist?(path)
          config(path)[key]
        end
      rescue Psych::SyntaxError => e
        raise InvalidSyntaxError.new e
      end

      private

      def config(path)
        YAML.load_file(path) || {}
      end
    end
  end
end
