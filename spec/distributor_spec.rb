require 'spec_helper'

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

  let(:book_repo_short_name) { 'fixture-book-title' }
  let(:book_repo_name) { "owner/#{book_repo_short_name}" }
  let(:namer_filename) { "#{book_repo_short_name}-#{build_number}.log" }
  let(:namer_full_path) { "/tmp/#{namer_filename}" }
  let(:fake_namer) { double(ArtifactNamer, filename: namer_filename, full_path: namer_full_path) }

  let(:distributor) do
    described_class.new(
      fake_archive,
      fake_pusher,
      book_repo_short_name,
      fake_namer,
      app_dir: fake_dir,
      aws_credentials: aws_credentials,
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
    it 'returns nil' do
      expect(distributor.distribute).to be_nil
    end

    context 'uploading the trace' do
      it 'uploads the tracefile to the archive after pushing' do
        expect(fake_pusher).to receive(:push).ordered
        expect(fake_archive).to receive(:upload_file).with(bucket, namer_filename, namer_full_path).ordered
        distributor.distribute
      end

      it "logs the tracefile's URL" do
        expect(fake_archive).to receive(:upload_file).and_return(fake_uploaded_file)
        allow(distributor).to receive(:log)
        expect(distributor).to receive(:log).with(/#{Regexp.escape(fake_url)}/)
        distributor.distribute
      end

      it 'uploads despite push raising' do
        allow(fake_pusher).to receive(:push).and_raise('Hi there')
        expect(fake_archive).to receive(:upload_file)
        expect { distributor.distribute }.to raise_error('Hi there')
      end

      context 'when download raises' do
        let(:production) { true }
        it 'uploads despite download raising' do
          allow(fake_archive).to receive(:download).and_raise('Hi there')
          expect(fake_archive).to receive(:upload_file)
          expect { distributor.distribute }.to raise_error('Hi there')
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
        allow(distributor).to receive(:log)
        expect(distributor).to receive(:log).with(/Warning.*production/)
        distributor.distribute
      end
    end

    context 'when not in production' do
      let(:production) { false }

      it 'does not download the repo' do
        expect(fake_archive).to_not receive(:download)
        distributor.distribute
      end

      it 'does not warn' do
        expect(distributor).not_to receive(:log).with(/Warning.*production/)
        distributor.distribute
      end
    end

    it 'pushes the repo' do
      expect(fake_pusher).to receive(:push).with(fake_dir)

      distributor.distribute
    end
  end

  describe '.build' do
    let(:cf_credentials) do
      Configuration::CfCredentials.new({
        'api_endpoint' => 'http://get.your.apis.here.io',
        'production_host' => 'http://get.your.apis.here.io',
        'organization' => 'foooo',
        'production_space' => 'foooo',
        'app_name' => 'foooo',
      }, true)
    end

    let(:options) do
      {
        book_repo: book_repo_name,
        app_dir: fake_dir,
        aws_credentials: aws_credentials,
        cf_credentials: cf_credentials,
        production: production,
        build_number: build_number,
      }
    end

    it 'creates the right objects' do
      expect(Book).to receive(:new).with({full_name: book_repo_name}).and_call_original
      real_namer = expect_to_receive_and_return_real_now(ArtifactNamer, :new, book_repo_short_name, build_number, 'log', '/tmp')
      real_archive = expect_to_receive_and_return_real_now(Archive, :new, key: key, secret: secret)
      real_runner = expect_to_receive_and_return_real_now(CfCommandRunner, :new, cf_credentials, namer_full_path)
      real_pusher = expect_to_receive_and_return_real_now(Pusher, :new, real_runner)

      expect(described_class).to receive(:new).with(real_archive, real_pusher, book_repo_short_name, real_namer, options)

      described_class.build(options)
    end
  end
end
