require 'active_support/core_ext/object/blank'
require_relative '../configuration'

module Bookbinder
  class ConfigVersionChecker
    def initialize(bookbinder_schema_version, starting_schema_version, messages, view_updater)
      @bookbinder_schema_version = bookbinder_schema_version
      @starting_schema_version = starting_schema_version
      @messages = messages
      @view_updater = view_updater
    end

    def check(config)
      user_schema_version = Version.parse(config['schema_version'])
      if user_schema_version.valid?
        if user_schema_version.major > bookbinder_schema_version.major
          raise Configuration::ConfigSchemaUnsupportedError.new messages.unrecognized_schema_version_message
        elsif user_schema_version.minor > bookbinder_schema_version.minor
          raise Configuration::ConfigSchemaUnsupportedError.new messages.unrecognized_schema_version_message
        elsif user_schema_version.patch > bookbinder_schema_version.patch
          raise Configuration::ConfigSchemaUnsupportedError.new messages.unrecognized_schema_version_message
        elsif user_schema_version.major < bookbinder_schema_version.major
          raise Configuration::ConfigSchemaUnsupportedError.new messages.incompatible_schema_message
        elsif user_schema_version.minor < bookbinder_schema_version.minor
          view_updater.warn nonbreaking_schema_message_for("minor")
        elsif user_schema_version.patch < bookbinder_schema_version.patch
          view_updater.warn nonbreaking_schema_message_for("patch")
        end
      elsif bookbinder_schema_version != starting_schema_version
        raise Configuration::ConfigSchemaUnsupportedError.new messages.schema_now_required_message
      end
    end

    private

    attr_reader :bookbinder_schema_version, :starting_schema_version, :messages, :view_updater

    def nonbreaking_schema_message_for(version_level)
      "[WARNING] Your schema is valid, but there exists a new #{version_level} version. Consider updating your config.yml."
    end
  end

  Version = Struct.new(:major, :minor, :patch) do
    class << self
      def parse(raw_version)
        if raw_version
          new(*raw_version.split('.'))
        else
          new(nil, nil, nil)
        end
      end
    end

    def valid?
      [major, minor, patch].all?(&:present?)
    end

    def to_s
      [major, minor, patch].compact.join('.')
    end
  end

  class VersionCheckerMessages
    def initialize(user_schema_version, bookbinder_schema_version)
      @user_schema_version = user_schema_version
      @bookbinder_schema_version = bookbinder_schema_version
    end

    def schema_now_required_message
      "[ERROR] Bookbinder now requires a certain schema. Please see README " +
          "and provide a schema version."
    end

    def incompatible_schema_message
      "[ERROR] Your config.yml format, schema version #{user_schema_version}, " +
          "is older than this version of Bookbinder can support. Please update " +
          "your config.yml keys and format to version #{bookbinder_schema_version} " +
          "and try again."
    end

    def unrecognized_schema_version_message
      "[ERROR] The config schema version #{user_schema_version} is " +
          "unrecognized by this version of Bookbinder. The latest schema version " +
          "is #{bookbinder_schema_version}."
    end

    private

    attr_reader :user_schema_version, :bookbinder_schema_version
  end
end