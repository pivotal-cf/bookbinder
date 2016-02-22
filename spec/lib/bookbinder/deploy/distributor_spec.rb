require_relative '../../../../lib/bookbinder/deploy/deployment'
require_relative '../../../../lib/bookbinder/deploy/distributor'
require_relative '../../../../lib/bookbinder/config/aws_credentials'
require_relative '../../../../lib/bookbinder/config/cf_credentials'
require_relative '../../../../lib/bookbinder/config/configuration'
require_relative '../../../helpers/tmp_dirs'

module Bookbinder
  module Deploy
    describe Distributor do
      include_context 'tmp_dirs'

      let(:build_number) { '17' }
      let(:key) { 'something' }
      let(:secret) { 'something-else' }
      let(:bucket) { 'bucket-name-in-fixture-config' }
      let(:aws_credentials) do
        Bookbinder::Config::AwsCredentials.new(
          'access_key' => key,
          'secret_key' => secret,
          'green_builds_bucket' => bucket
        )
      end

      let(:cf_credentials) do
        Bookbinder::Config::CfCredentials.new({
          'api_endpoint' => 'http://get.your.apis.here.io',
          'env' => {
            'staging' => {
              'host' => {
                'http://get.your.apis.for.staging.here.io' => ['a_staging_host']
              },
              'space' => 'foo_stage'
            }
          },
          'organization' => 'foooo',
          'app_name' => 'foooo',
          'username' => 'username'
        }, 'staging')
      end

      let(:book_repo_short_name) { 'fixture-book-title' }
      let(:book_repo_name) { "owner/#{book_repo_short_name}" }
      let(:expected_artifact_filename) { "#{book_repo_short_name}-#{build_number}.log" }
      let(:expected_artifact_full_path) { "/tmp/#{expected_artifact_filename}" }

      let(:deployment) {
        Deployment.new(app_dir: fake_dir,
                       aws_credentials: aws_credentials,
                       book_repo: book_repo_name,
                       build_number: build_number,
                       cf_credentials: cf_credentials)
      }

      let(:distributor) do
        Distributor.new(
          {success: StringIO.new, out: StringIO.new, err: StringIO.new},
          fake_archive,
          fake_pusher,
          deployment
        )
      end

      let(:fake_dir) { 'my-directory/path/path/stuff' }
      let(:fake_archive) { double('archiver') }
      let(:fake_cf) { double }
      let(:fake_pusher) { double }
      let(:fake_uploaded_file) { double(url: fake_url) }
      let(:fake_url) { 'http://example.com/trace_log_file' }

      before do
        allow(fake_pusher).to receive(:push)
        allow(fake_archive).to receive(:upload_file).and_return(fake_uploaded_file)
      end

      describe '#distribute' do
        context 'uploading the trace' do
          it 'uploads the tracefile to the archive after pushing' do
            allow(fake_archive).to receive(:download)
            expect(fake_pusher).to receive(:push).ordered
            expect(fake_archive).to receive(:upload_file).with(bucket, expected_artifact_filename, expected_artifact_full_path).ordered
            distributor.distribute
          end

          it 'logs the tracefile URL' do
            expect(fake_archive).to receive(:upload_file).and_return(fake_uploaded_file)
            allow(fake_archive).to receive(:download)

            success = StringIO.new
            distributor = Distributor.new(
              {success: success, out: StringIO.new, err: StringIO.new},
              fake_archive,
              fake_pusher,
              deployment
            )
            distributor.distribute
            expect(success.tap(&:rewind).read).to match(/#{Regexp.escape(fake_url)}/)
          end

          it 'uploads despite push raising' do
            allow(fake_pusher).to receive(:push).and_raise(SpecialException)
            allow(fake_archive).to receive(:download)
            expect(fake_archive).to receive(:upload_file)
            rescued_distribute
          end

          context 'when download raises' do
            it 'uploads despite download raising' do
              allow(fake_archive).to receive(:download).and_raise(SpecialException)
              expect(fake_archive).to receive(:upload_file)
              rescued_distribute
            end
          end

          context "when file isn't available to upload" do
            before do
              allow(fake_archive).to receive(:download)
              allow(fake_archive).to receive(:upload_file).and_raise(Errno::ENOENT.new)
            end

            it 'logs a message' do
              err = StringIO.new
              distributor = Distributor.new(
                {success: StringIO.new, out: StringIO.new, err: err},
                fake_archive,
                fake_pusher,
                deployment
              )
              distributor.distribute
              expect(err.tap(&:rewind).read).to eq("Could not find CF trace file: #{expected_artifact_full_path}\n")
            end
          end
        end

        context 'when an error is thrown from pushing an app' do
          it 'logs an informative message' do
            allow(fake_pusher).to receive(:push).and_raise(SpecialException.new("failed to push because of reason."))
            err = StringIO.new
            distributor = Distributor.new(
              {success: StringIO.new, out: StringIO.new, err: err},
              fake_archive,
              fake_pusher,
              deployment
            )
            begin
              distributor.distribute
            rescue SpecialException
            end
            expect(err.tap(&:rewind).read).to eq(<<-ERROR_MESSAGE)
  [ERROR] failed to push because of reason.
  [DEBUG INFO]
  CF organization: foooo
  CF space: foo_stage
  CF account: username
  routes: #{cf_credentials.routes}
  ERROR_MESSAGE
          end

          it 'raises an exception' do
            error = RuntimeError.new('Failed to push because of reason')
            allow(fake_pusher).to receive(:push).and_raise(error)
            expect { distributor.distribute }.to raise_error(error)
          end
        end
      end

      it 'pushes the repo' do
        allow(fake_archive).to receive(:download)
        expect(fake_pusher).to receive(:push).with(fake_dir)
        distributor.distribute
      end

      SpecialException = Class.new(RuntimeError)

      def rescued_distribute
        distributor.distribute
      rescue SpecialException
      end
    end
  end
end
