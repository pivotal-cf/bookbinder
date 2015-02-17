require 'spec_helper'

module Bookbinder
  describe Distributor do
    include_context 'tmp_dirs'

    let(:build_number) { '17' }
    let(:key) { 'something' }
    let(:secret) { 'something-else' }
    let(:bucket) { 'bucket-name-in-fixture-config' }
    let(:aws_credentials) do
      Configuration::AwsCredentials.new({
                                            'access_key' => key,
                                            'secret_key' => secret,
                                            'green_builds_bucket' => bucket
                                        })
    end

    let(:cf_credentials) do
      Configuration::CfCredentials.new({
                                           'api_endpoint' => 'http://get.your.apis.here.io',
                                           'production_host' => {
                                               'get.your.apis.here.io' => 'a_production_host'
                                            },
                                           'organization' => 'foooo',
                                           'production_space' => 'foooo',
                                           'app_name' => 'foooo',
                                           'username' => 'username'
                                       }, true)
    end

    let(:book_repo_short_name) { 'fixture-book-title' }
    let(:book_repo_name) { "owner/#{book_repo_short_name}" }
    let(:namer_filename) { "#{book_repo_short_name}-#{build_number}.log" }
    let(:namer_full_path) { "/tmp/#{namer_filename}" }
    let(:fake_namer) { double(ArtifactNamer, filename: namer_filename, full_path: namer_full_path) }
    let(:logger) { NilLogger.new }

    let(:distributor) do
      described_class.new(
          logger,
          fake_archive,
          fake_pusher,
          book_repo_short_name,
          fake_namer,
          app_dir: fake_dir,
          aws_credentials: aws_credentials,
          cf_credentials: cf_credentials,
          production: production,
          build_number: build_number
      )
    end

    let(:fake_dir) { 'my-directory/path/path/stuff' }
    let(:fake_archive) { double }
    let(:fake_cf) { double }
    let(:fake_pusher) { double }
    let(:fake_uploaded_file) { double(url: fake_url) }
    let(:fake_url) { 'http://example.com/trace_log_file' }
    let(:production) { false }

    before do
      allow(fake_pusher).to receive(:push)
      allow(fake_archive).to receive(:upload_file).and_return(fake_uploaded_file)
    end

    describe '#distribute' do
      context 'uploading the trace' do
        it 'uploads the tracefile to the archive after pushing' do
          expect(fake_pusher).to receive(:push).ordered
          expect(fake_archive).to receive(:upload_file).with(bucket, namer_filename, namer_full_path).ordered
          distributor.distribute
        end

        it 'logs the tracefile URL' do
          expect(fake_archive).to receive(:upload_file).and_return(fake_uploaded_file)
          allow(logger).to receive(:log)
          expect(logger).to receive(:log).with(/#{Regexp.escape(fake_url)}/)
          distributor.distribute
        end

        it 'uploads despite push raising' do
          allow(fake_pusher).to receive(:push).and_raise('Hi there')
          expect(fake_archive).to receive(:upload_file)
          distributor.distribute
        end

        context 'when download raises' do
          let(:production) { true }
          it 'uploads despite download raising' do
            allow(fake_archive).to receive(:download).and_raise('Hi there')
            expect(fake_archive).to receive(:upload_file)
            distributor.distribute
          end
        end

        context 'fails' do
          before do
            allow(fake_archive).to receive(:upload_file).and_raise(Errno::ENOENT.new)
          end

          it 'logs a message' do
            expect(logger).to receive(:error).with(/Could not find CF trace file: #{namer_full_path}/)
            distributor.distribute
          end
        end
      end

      context 'when in production' do
        let(:production) { true }

        before do
          allow(fake_archive).to receive(:download)
        end

        it 'downloads the repo' do
          download_args = {
              download_dir: fake_dir,
              bucket: bucket,
              build_number: build_number,
              namespace: book_repo_short_name
          }
          expect(fake_archive).to receive(:download).with(download_args)
          distributor.distribute
        end

        it 'warns' do
          expect(logger).to receive(:warn).with(/Warning.*production/)
          distributor.distribute
        end

        context 'when an error is thrown from downloading' do
          let(:error_message) {
            "[ERROR] failed to download because of reason.\n[DEBUG INFO]\nCF organization: foooo\nCF space: foooo\nCF account: username\nroutes: #{cf_credentials.production_host}"
          }
          it 'logs an informative message' do
            allow(fake_archive).to receive(:download).and_raise("failed to download because of reason.")
            expect(logger).to receive(:error).with(error_message)

            distributor.distribute
          end
        end

        context 'when an error is thrown from pushing' do
          let(:error_message) {
            "[ERROR] failed to push because of reason.\n[DEBUG INFO]\nCF organization: foooo\nCF space: foooo\nCF account: username\nroutes: #{cf_credentials.production_host}"
          }
          it 'logs an informative message' do
            allow(fake_pusher).to receive(:push).and_raise("failed to push because of reason.")
            expect(logger).to receive(:error).with(error_message)

            distributor.distribute
          end
        end
      end

      context 'when not in production' do
        let(:production) { false }
        let(:cf_credentials) do
          Configuration::CfCredentials.new({
          'api_endpoint' => 'http://get.your.apis.here.io',
          'staging_host' => {
              'http://get.your.apis.for.staging.here.io' => 'a_staging_host'
          },
          'organization' => 'foooo',
          'staging_space' => 'foo_stage',
          'app_name' => 'foooo',
          'username' => 'username'
          }, false)
        end

        it 'does not download the repo' do
          expect(fake_archive).to_not receive(:download)
          distributor.distribute
        end

        it 'does not warn' do
          expect(logger).not_to receive(:log).with(/Warning.*production/)
          distributor.distribute
        end

        context 'when an error is thrown from pushing an app' do
          let(:error_message) {
            "[ERROR] failed to push because of reason.\n[DEBUG INFO]\nCF organization: foooo\nCF space: foo_stage\nCF account: username\nroutes: #{cf_credentials.staging_host}"
          }
          it 'logs an informative message' do
            allow(fake_pusher).to receive(:push).and_raise("failed to push because of reason.")
            expect(logger).to receive(:error).with(error_message)

            distributor.distribute
          end
        end
      end

      it 'pushes the repo' do
        expect(fake_pusher).to receive(:push).with(fake_dir)

        distributor.distribute
      end
    end
  end
end
