require_relative '../../../../lib/bookbinder/validation_checkers/config_version_checker'

module Bookbinder
  describe ConfigVersionChecker do
    context 'when the configuration hash is populated' do
      let(:starting_schema_version) { Version.parse('1.0.0') }

      context 'when the user has specified a config schema version' do
        context 'when config schema version is supported' do
          context 'and matches the latest version' do
            it 'should return true' do
              user_schema_version = '1.0.0'
              bookbinder_schema_version = Version.parse('1.0.0')
              config_hash = { 'schema_version' => user_schema_version }
              versionCheckerMessages = VersionCheckerMessages.new(user_schema_version, bookbinder_schema_version)
              view_updater = double('view_updater', warn: nil)
              expect(ConfigVersionChecker.new(bookbinder_schema_version,
                                              starting_schema_version,
                                              versionCheckerMessages,
                                              view_updater).check(config_hash)).to be_nil
            end
          end

          context 'but there exists a new minor version' do

            it 'logs an informative error message' do
              user_schema_version = '1.0.0'
              bookbinder_schema_version = Version.parse('1.2.0')
              config_hash = { 'schema_version' => user_schema_version }
              versionCheckerMessages = VersionCheckerMessages.new(user_schema_version, bookbinder_schema_version)
              view_updater = double('view_updater', warn: nil)
              config_version_checker = ConfigVersionChecker.new(bookbinder_schema_version,
                                                                starting_schema_version,
                                                                versionCheckerMessages,
                                                                view_updater)

              expect(view_updater).to receive(:warn).with /minor version/

              config_version_checker.check config_hash
            end
          end

          context 'but there exists a new patch version' do
            it 'logs an informative error message' do
              user_schema_version = '1.0.0'
              bookbinder_schema_version = Version.parse('1.0.2')
              config_hash = { 'schema_version' => user_schema_version }
              versionCheckerMessages = VersionCheckerMessages.new(user_schema_version, bookbinder_schema_version)
              view_updater = double('view_updater', warn: nil)
              config_version_checker = ConfigVersionChecker.new(bookbinder_schema_version,
                                                                starting_schema_version,
                                                                versionCheckerMessages,
                                                                view_updater)

              expect(view_updater).to receive(:warn).with /patch version/

              config_version_checker.check config_hash
            end
          end
        end

        context 'when config schema version is not recognized by bookbinder' do
          context 'and the major version is unknown' do
            it 'raises a ConfigSchemaUnsupportedError' do
              bookbinder_schema_version = Version.parse('1.0.0')
              user_schema_version = '3.0.0'
              config_hash = { 'schema_version' => user_schema_version }
              versionCheckerMessages = VersionCheckerMessages.new(user_schema_version, bookbinder_schema_version)
              config_version_checker = ConfigVersionChecker.new(bookbinder_schema_version,
                                                                starting_schema_version,
                                                                versionCheckerMessages,
                                                                nil)

              expect { config_version_checker.check config_hash }.
                  to raise_error Configuration::ConfigSchemaUnsupportedError, "[ERROR] The config schema version #{user_schema_version} is unrecognized by this version of Bookbinder. The latest schema version is #{bookbinder_schema_version}."
            end
          end

          context 'and the minor version is unknown' do
            it 'raises a ConfigSchemaUnsupportedError' do
              bookbinder_schema_version = Version.parse('1.0.0')
              user_schema_version = '2.1.0'
              config_hash = { 'schema_version' => user_schema_version }
              versionCheckerMessages = VersionCheckerMessages.new(user_schema_version, bookbinder_schema_version)
              config_version_checker = ConfigVersionChecker.new(bookbinder_schema_version,
                                                                starting_schema_version,
                                                                versionCheckerMessages,
                                                                nil)
              expect { config_version_checker.check config_hash }.
                  to raise_error Configuration::ConfigSchemaUnsupportedError, "[ERROR] The config schema version #{user_schema_version} is unrecognized by this version of Bookbinder. The latest schema version is #{bookbinder_schema_version}."
            end
          end

          context 'and the patch version is unknown' do
            it 'raises a ConfigSchemaUnrecogizedError' do
              bookbinder_schema_version = Version.parse('1.0.0')
              user_schema_version = '2.0.1'
              config_hash = { 'schema_version' => user_schema_version }
              versionCheckerMessages = VersionCheckerMessages.new(user_schema_version, bookbinder_schema_version)
              config_version_checker = ConfigVersionChecker.new(bookbinder_schema_version,
                                                                starting_schema_version,
                                                                versionCheckerMessages,
                                                                nil)
              expect { config_version_checker.check config_hash }.
                  to raise_error Configuration::ConfigSchemaUnsupportedError, "[ERROR] The config schema version #{user_schema_version} is unrecognized by this version of Bookbinder. The latest schema version is #{bookbinder_schema_version}."
            end
          end

        end

        context 'when config schema version is unsupported due to a new major version' do
          it 'raises a ConfigSchemaUnsupportedError' do
            bookbinder_schema_version = Version.parse('2.0.0')
            user_schema_version = '1.0.0'
            config_hash = { 'schema_version' => user_schema_version }
            versionCheckerMessages = VersionCheckerMessages.new(user_schema_version, bookbinder_schema_version)
            config_version_checker = ConfigVersionChecker.new(bookbinder_schema_version,
                                                              starting_schema_version,
                                                              versionCheckerMessages,
                                                              nil)
            expect { config_version_checker.check config_hash }.
                to raise_error Configuration::ConfigSchemaUnsupportedError, "[ERROR] Your config.yml format, schema version #{user_schema_version}, is older than this version of Bookbinder can support. Please update your config.yml keys and format to version #{bookbinder_schema_version} and try again."
          end
        end
      end

      context 'when the user has not specified a config schema version' do
        context 'when bookbinder is 1.0.0' do
          bookbinder_schema_version = Version.parse('1.0.0')
          config_hash = { }
          versionCheckerMessages = VersionCheckerMessages.new('', bookbinder_schema_version)
          config_version_checker = ConfigVersionChecker.new(bookbinder_schema_version,
                                                            Version.parse('1.0.0'),
                                                            versionCheckerMessages,
                                                            nil)
          it 'should not raise an error' do
            expect { config_version_checker.check config_hash }.to_not raise_error
          end

          it 'should validate the object' do
            expect(config_version_checker.check config_hash).to be_nil
          end
        end

        context 'when bookbinder is not 1.0.0' do
          bookbinder_schema_version = Version.parse('1.0.1')
          config_hash = { }
          versionCheckerMessages = VersionCheckerMessages.new('', bookbinder_schema_version)
          config_version_checker = ConfigVersionChecker.new(bookbinder_schema_version,
                                                            Version.parse('1.0.0'),
                                                            versionCheckerMessages,
                                                            nil)

          it 'raises a ConfigSchemaUnsupportedError' do
            expect { config_version_checker.check config_hash }.
                to raise_error Configuration::ConfigSchemaUnsupportedError, "[ERROR] Bookbinder now requires a certain schema. Please see README and provide a schema version."
          end
        end
      end
    end
  end
end
