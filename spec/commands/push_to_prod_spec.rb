require 'spec_helper'

describe Cli::PushToProd do
  include_context 'tmp_dirs'

  let(:build_number) { '17' }
  let(:key) { 'something' }
  let(:secret) { 'something-else' }
  let(:bucket) { 'bucket-name-in-fixture-config' }
  let(:aws_credentials) do
    {
      'access_key' => key,
      'secret_key' => secret,
      'green_builds_bucket' => bucket
    }
  end
  let(:cf_credentials) do
    {
      'api_endpoint' => 'http://get.your.apis.here.io',
      'production_host' => 'http://get.your.apis.here.io',
      'organization' => 'foooo',
      'production_space' => 'foooo',
      'app_name' => 'foooo',
    }
  end

  let(:book_repo_name) { 'fixture-book-title' }
  let(:config_hash) do
    {
      'book_repo' => "my-user/#{book_repo_name}",
      'cred_repo' => 'whatever',
      'aws' => aws_credentials,
      'cloud_foundry' => cf_credentials
    }
  end
  let(:config) { Configuration.new(config_hash) }
  let(:command) { Cli::PushToProd.new(config) }

  let(:fake_dir) { double }
  let(:fake_repo) { double }
  let(:fake_cf) { double }
  let(:fake_pusher) { double }

  before do
    fake_cred_repo = double
    fake_cred_repo.stub(:credentials).and_return({'aws' => aws_credentials,
                                                  'cloud_foundry' => cf_credentials})
    CredRepo.stub(:new).and_return(fake_cred_repo)
  end

  it 'downloads the repo and pushes it' do
    expect(Dir).to receive(:mktmpdir).and_return(fake_dir)
    expect(Archive).to receive(:new).with(key: key, secret: secret).and_return(fake_repo)
    download_args = {
      download_dir: fake_dir,
      bucket: bucket,
      build_number: build_number,
      namespace: book_repo_name
    }
    expect(fake_repo).to receive(:download).with(download_args)

    allow(CfCommandRunner).to receive(:new).and_return(fake_cf)
    expect(Pusher).to receive(:new).with(fake_cf).and_return(fake_pusher)
    expect(fake_pusher).to receive(:push).with(fake_dir)

    expect(command.run([build_number])).to eq(0)
  end

  it "names the Command Runner's tracefile after the book" do
    allow(Archive).to receive(:new).and_return(fake_repo)
    allow(fake_repo).to receive(:download)

    trace_file_path = "/tmp/#{book_repo_name}-#{build_number}.log"
    expect(CfCommandRunner).to receive(:new).with(config.cf_production_credentials, trace_file_path)
    command.run([build_number])
  end
end
