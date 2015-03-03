require 'spec_helper'

module Bookbinder
  describe ConfigurationValidator do
    let(:logger) { NilLogger.new }
    let(:bookbinder_schema_version) { '1.0.0' }
    let(:user_schema_version) { '1.0.0' }
    let(:file_system_accessor) { double 'fileSystemAccessor', file_exist?: true }
    let(:subject) { ConfigurationValidator.new(logger, file_system_accessor) }

    describe 'validating the configuration hash' do
      context 'when the config hash is empty' do
        let(:config_hash) { nil }
        it 'raises an informative error' do
          expect { subject.valid? config_hash, bookbinder_schema_version, user_schema_version }.to raise_error /Your config.yml appears to be empty. Please check and try again./
        end
      end
      context 'when the required key is missing' do
        let(:config_hash) do
          {
              'versions' => %w(v1.7.1.9 redacted v3),
          }
        end

        it 'raises missing key error' do
          expect { subject.valid? config_hash, bookbinder_schema_version, user_schema_version }.to raise_error ConfigurationValidator::MissingRequiredKeyError
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
              'archive_menu' => archive_menu,
              'pdf' => 'pdf',
              'pdf_index' => 'pdf_index'
          }
        end

        context 'when the user has specified a config schema version' do
          context 'when config schema version is supported' do
            context 'and matches the latest version' do
              let(:user_schema_version) { '1.0.0' }
              let(:bookbinder_schema_version) { '1.0.0' }

              it 'should return true' do
                expect(subject.valid? config_hash, bookbinder_schema_version, user_schema_version).to eq true
              end
            end

            context 'but there exists a new minor version' do
              let(:user_schema_version) { '1.0.0' }
              let(:bookbinder_schema_version)   { '1.2.0' }

              it 'logs an informative error message' do
                expect(logger).to receive(:warn).with "[WARNING] Your schema is valid, but there exists a new minor version. Consider updating your config.yml."
                expect(subject.valid? config_hash, bookbinder_schema_version, user_schema_version).to eq true
              end
            end

            context 'but there exists a new patch version' do
              let(:user_schema_version) { '1.0.0' }
              let(:bookbinder_schema_version)   { '1.0.2' }

              it 'logs an informative error message' do
                expect(logger).to receive(:warn).with "[WARNING] Your schema is valid, but there exists a new patch version. Consider updating your config.yml."
                expect(subject.valid? config_hash, bookbinder_schema_version, user_schema_version).to eq true
              end
            end
          end

          context 'when config schema version is not recognized by bookbinder' do
            let(:bookbinder_schema_version) { '1.0.0' }

            context 'and the major version is unknown' do
              let(:user_schema_version) { '3.0.0' }
              it 'raises a ConfigSchemaUnrecognizedError' do
                expect { subject.valid? config_hash, bookbinder_schema_version, user_schema_version }.to raise_error Configuration::ConfigSchemaUnsupportedError, "[ERROR] The config schema version #{user_schema_version} is unrecognized by this version of Bookbinder. The latest schema version is #{bookbinder_schema_version}."
              end
            end

            context 'and the minor version is unknown' do
              let(:user_schema_version) { '2.1.0' }
              it 'raises a ConfigSchemaUnrecognizedError' do
                expect { subject.valid? config_hash, bookbinder_schema_version, user_schema_version }.to raise_error Configuration::ConfigSchemaUnsupportedError, "[ERROR] The config schema version #{user_schema_version} is unrecognized by this version of Bookbinder. The latest schema version is #{bookbinder_schema_version}."
              end
            end

            context 'and the patch version is unknown' do
              let(:user_schema_version) { '2.0.1' }
              it 'raises a ConfigSchemaUnrecogizedError' do
                expect { subject.valid? config_hash, bookbinder_schema_version, user_schema_version }.to raise_error Configuration::ConfigSchemaUnsupportedError, "[ERROR] The config schema version #{user_schema_version} is unrecognized by this version of Bookbinder. The latest schema version is #{bookbinder_schema_version}."
              end
            end

          end

          context 'when config schema version is unsupported due to a new major version' do
            let(:user_schema_version) { '1.0.0' }
            let(:bookbinder_schema_version)   { '2.0.0' }

            it 'raises a ConfigSchemaUnsupportedError' do
              expect { subject.valid? config_hash, bookbinder_schema_version, user_schema_version }.to raise_error Configuration::ConfigSchemaUnsupportedError, "[ERROR] Your config.yml format, schema version #{user_schema_version}, is older than this version of Bookbinder can support. Please update your config.yml keys and format to version #{bookbinder_schema_version} and try again."
            end
          end
        end

        context 'when the user has not specified a config schema version' do
          before { config_hash.delete("schema_version") }

          context 'when bookbinder is 1.0.0' do
            it 'should not raise an error' do
              expect { subject.valid? config_hash, bookbinder_schema_version, user_schema_version }.to_not raise_error
            end

            it 'should validate the object' do
              expect(subject.valid? config_hash, bookbinder_schema_version, user_schema_version).to eq true
            end
          end

          context 'when bookbinder is not 1.0.0' do
            let(:bookbinder_schema_version) { '1.0.2' }

            it 'raises a ConfigSchemaUnrecognizedError' do
              expect { subject.valid? config_hash, bookbinder_schema_version, user_schema_version }.to raise_error Configuration::ConfigSchemaUnsupportedError, "[ERROR] Bookbinder now requires a certain schema. Please see README and provide a schema version."
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

        valid_config_hash = {
          'book_repo' => 'my_book',
              'cred_repo' => 'my_cred_repo',
              'public_host' => 'public_host',
              'pdf' => 'pdf',
              'pdf_index' => 'pdf_index',
              'sections' => [section1, section2]
        }

        expect(subject.valid?(valid_config_hash, bookbinder_schema_version, user_schema_version)).to eq true
      end

      it 'should be invalid when directory names are not unique' do
        section1 = {
            'repository' => {
                'name' => 'cloudfoundry/docs-cloudfoundry-concepts'
            },
            'directory' => 'concepts'
        }

        invalid_config_hash = {
            'book_repo' => 'my_book',
            'cred_repo' => 'my_cred_repo',
            'public_host' => 'public_host',
            'pdf' => 'pdf',
            'pdf_index' => 'pdf_index',
            'sections' => [section1, section1]
        }

        expect{subject.valid? invalid_config_hash, bookbinder_schema_version, user_schema_version}.to raise_error ConfigurationValidator::DuplicateSectionNameError
      end

      context 'when there are no markdown sections' do
        it 'should pass validation' do
          invalid_config_hash = {
              'book_repo' => 'my_book',
              'cred_repo' => 'my_cred_repo',
              'public_host' => 'public_host',
              'pdf' => 'pdf',
              'pdf_index' => 'pdf_index',
          }

          expect(subject.valid? invalid_config_hash, bookbinder_schema_version, user_schema_version).to be_truthy

        end
      end
    end

    describe 'validating the archive_menu' do
      context "when there's an archive_menu key and the partial is present" do
        it "returns true" do
          config = {
            'archive_menu' => [
              'v1.3.0.0'
            ],
            'sections' => [
              {
                'repository' => {
                  'name' => 'cloudfoundry/docs-cloudfoundry-concepts'
                }
              }
            ],
            'book_repo' => 'my_book',
            'cred_repo' => 'my_cred_repo',
            'public_host' => 'public_host',
            'pdf' => 'pdf',
            'pdf_index' => 'pdf_index'
          }

          expect(subject.valid?(config, bookbinder_schema_version, user_schema_version)).to be_truthy
        end
      end

      context 'when there is an archive_menu key but the corresponding partial does not exist' do
        let(:archive_menu_path) {}

        before do
          allow(file_system_accessor).to receive(:file_exist?).and_return false
        end

        it 'raises an exception' do
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

          valid_config_hash = {
              'archive_menu' => [
                  'v1.3.0.0'
              ],
              'sections' => [section1, section2],
              'book_repo' => 'my_book',
              'cred_repo' => 'my_cred_repo',
              'public_host' => 'public_host',
              'pdf' => 'pdf',
              'pdf_index' => 'pdf_index'
          }

          expect { subject.valid? valid_config_hash, bookbinder_schema_version, user_schema_version }.to raise_error ConfigurationValidator::MissingArchiveMenuPartialError
        end
      end

      context "when there is no archive_menu and no partial" do
        it "returns true" do
          allow(file_system_accessor).to receive(:file_exist?).and_return false

          config = {
            'book_repo' => 'my_book',
            'cred_repo' => 'my_cred_repo',
            'public_host' => 'public_host',
            'pdf' => 'pdf',
            'pdf_index' => 'pdf_index',
            'sections' => [
              {
                'repository' => {
                  'name' => 'cloudfoundry/docs-cloudfoundry-foo'
                },
              }
            ]
          }

          expect(subject.valid? config, bookbinder_schema_version, user_schema_version).to be_truthy
        end
      end

      context 'when there is an archive_menu but an item is empty' do
        it 'raises an exception' do
          config = {
            'archive_menu' => [ nil ],
            'sections' => [
              {
                'repository' => {
                  'name' => 'cloudfoundry/docs-cloudfoundry-foo'
                },
              }
            ],
            'book_repo' => 'my_book',
            'cred_repo' => 'my_cred_repo',
            'public_host' => 'public_host',
            'pdf' => 'pdf',
            'pdf_index' => 'pdf_index'
          }
          expect { subject.valid? config, bookbinder_schema_version, user_schema_version }.
            to raise_error ConfigurationValidator::EmptyArchiveItemsError
        end
      end

      context 'when there is an empty archive_menu key' do
        it "raises an exception" do
          config = {
            'archive_menu' => nil,
            'sections' => [
              {
                'repository' => {
                  'name' => 'cloudfoundry/docs-cloudfoundry-foo'
                }
              }
            ],
            'book_repo' => 'my_book',
            'cred_repo' => 'my_cred_repo',
            'public_host' => 'public_host',
            'pdf' => 'pdf',
            'pdf_index' => 'pdf_index'
          }
          expect { subject.valid? config, bookbinder_schema_version, user_schema_version }.
            to raise_error ConfigurationValidator::ArchiveMenuNotDefinedError
        end
      end
    end
  end
end
