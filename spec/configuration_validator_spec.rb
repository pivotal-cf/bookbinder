require 'spec_helper'

module Bookbinder
  describe ConfigurationValidator do
    let(:logger) { NilLogger.new }
    let(:bookbinder_schema_version) { '1.0.0' }
    let(:user_schema_version) { '1.0.0' }
    let(:config_validator) { ConfigurationValidator.new(logger) }

    before do
      allow(config_validator).to receive(:bookbinder_schema_version).and_return bookbinder_schema_version
    end

    describe 'validating the configuration hash' do
      context 'when the config hash is empty' do
        let(:config_hash) { nil }
        it 'raises an informative error' do
          expect { config_validator.valid? config_hash }.to raise_error /Your config.yml appears to be empty. Please check and try again./
        end
      end

      context 'when the configuration hash is populated' do
        let(:archive_menu) { [] }
        let(:section1) do
          {
              'repository' => {
                  'name' => 'foo/dogs-repo'
              },
              'directory' => 'concepts'
          }
        end
        let(:config_hash) do
          {
              'book_repo' => 'some-org/some-repo',
              'versions' => %w(v1.7.1.9 redacted v3),
              'cred_repo' => 'some-org/cred-repo',
              'layout_repo' => 'some-org/some-repo',
              'sections' => [section1],
              'public_host' => 'http://www.example.com',
              'template_variables' => {'some-var' => 'some-value'},
              'schema_version' => user_schema_version,
              'archive_menu' => archive_menu
          }
        end

        context 'when the user has specified a config schema version' do
          context 'when config schema version is supported' do
            context 'and matches the latest version' do
              let(:user_schema_version) { '1.0.0' }
              let(:bookbinder_schema_version) { '1.0.0' }

              it 'should return true' do
                expect(config_validator.valid? config_hash).to eq true
              end
            end

            context 'but there exists a new minor version' do
              let(:user_schema_version) { '1.0.0' }
              let(:bookbinder_schema_version)   { '1.2.0' }

              it 'logs an informative error message' do
                expect(logger).to receive(:warn).with "[WARNING] Your schema is valid, but there exists a new minor version. Consider updating your config.yml."
                expect(config_validator.valid? config_hash).to eq true
              end
            end

            context 'but there exists a new patch version' do
              let(:user_schema_version) { '1.0.0' }
              let(:bookbinder_schema_version)   { '1.0.2' }

              it 'logs an informative error message' do
                expect(logger).to receive(:warn).with "[WARNING] Your schema is valid, but there exists a new patch version. Consider updating your config.yml."
                expect(config_validator.valid? config_hash).to eq true
              end
            end
          end

          context 'when config schema version is not recognized by bookbinder' do
            let(:bookbinder_schema_version) { '1.0.0' }

            context 'and the major version is unknown' do
              let(:user_schema_version) { '3.0.0' }
              it 'raises a ConfigSchemaUnrecognizedError' do
                expect { config_validator.valid? config_hash }.to raise_error Configuration::ConfigSchemaUnsupportedError, "[ERROR] The config schema version #{user_schema_version} is unrecognized by this version of Bookbinder. The latest schema version is #{bookbinder_schema_version}."
              end
            end

            context 'and the minor version is unknown' do
              let(:user_schema_version) { '2.1.0' }
              it 'raises a ConfigSchemaUnrecognizedError' do
                expect { config_validator.valid? config_hash }.to raise_error Configuration::ConfigSchemaUnsupportedError, "[ERROR] The config schema version #{user_schema_version} is unrecognized by this version of Bookbinder. The latest schema version is #{bookbinder_schema_version}."
              end
            end

            context 'and the patch version is unknown' do
              let(:user_schema_version) { '2.0.1' }
              it 'raises a ConfigSchemaUnrecogizedError' do
                expect { config_validator.valid? config_hash }.to raise_error Configuration::ConfigSchemaUnsupportedError, "[ERROR] The config schema version #{user_schema_version} is unrecognized by this version of Bookbinder. The latest schema version is #{bookbinder_schema_version}."
              end
            end

          end

          context 'when config schema version is unsupported due to a new major version' do
            let(:user_schema_version) { '1.0.0' }
            let(:bookbinder_schema_version)   { '2.0.0' }

            it 'raises a ConfigSchemaUnsupportedError' do
              expect { config_validator.valid? config_hash }.to raise_error Configuration::ConfigSchemaUnsupportedError, "[ERROR] Your config.yml format, schema version #{user_schema_version}, is older than this version of Bookbinder can support. Please update your config.yml keys and format to version #{bookbinder_schema_version} and try again."
            end
          end
        end

        context 'when the user has not specified a config schema version' do
          before { config_hash.delete("schema_version") }

          context 'when bookbinder is 1.0.0' do
            it 'should not raise an error' do
              expect { config_validator.valid? config_hash }.to_not raise_error
            end

            it 'should validate the object' do
              expect(config_validator.valid? config_hash).to eq true
            end
          end

          context 'when bookbinder is not 1.0.0' do
            let(:bookbinder_schema_version) { '1.0.2' }

            it 'raises a ConfigSchemaUnrecognizedError' do
              expect { config_validator.valid? config_hash }.to raise_error Configuration::ConfigSchemaUnsupportedError, "[ERROR] Bookbinder now requires a certain schema. Please see README and provide a schema version."
            end
          end
        end
      end
    end

    describe 'validating the sections' do
      it 'should be valid when directory names are unique' do
        section1 = {
            'repository' => {
                'name' => 'cloudfoundry/docs-cloudfoundry-concepts'
            },
            'directory' => 'concepts'
        }

        section2 = {
            'repository' => {
                'name' => 'cloudfoundry/docs-cloudfoundry-foo'
            },
            'directory' => 'foo'
        }

        valid_config_hash = {'sections' => [section1, section2]}

        expect(config_validator.valid?(valid_config_hash)).to eq true
      end

      it 'should be invalid when directory names are not unique' do
        section1 = {
            'repository' => {
                'name' => 'cloudfoundry/docs-cloudfoundry-concepts'
            },
            'directory' => 'concepts'
        }
        invalid_config_hash = {'sections' => [section1, section1]}

        expect{config_validator.valid? invalid_config_hash}.to raise_error ConfigurationValidator::DuplicateSectionNameError
      end
    end
  end
end
