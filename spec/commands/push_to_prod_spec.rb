require 'spec_helper'

describe Cli::PushToProd do
  include_context 'tmp_dirs'

  let(:build_number) { '17' }
  let(:aws_credentials) do
    {
      'access_key' => 'something',
      'secret_key' => 'something-else',
      'green_builds_bucket' => 'bucket-name-in-fixture-config'
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
  let(:org) { 'my-user' }
  let(:config_hash) do
    {
      'book_repo' => "#{org}/#{book_repo_name}",
      'cred_repo' => 'whatever',
      'aws' => aws_credentials,
      'cloud_foundry' => cf_credentials
    }
  end
  let(:config) { Configuration.new(config_hash) }
  let(:command) { Cli::PushToProd.new(config) }

  before do
    fake_cred_repo = double
    fake_cred_repo.stub(:credentials).and_return({'aws' => aws_credentials,
                                                  'cloud_foundry' => cf_credentials})
    CredRepo.stub(:new).and_return(fake_cred_repo)
  end

  it 'should call GreenBuildRepository#download with correct parameters' do
    GreenBuildRepository.any_instance.should_receive(:download) do |args|
      args.should have_key(:download_dir)
      args.should have_key(:bucket)
      args.should have_key(:build_number)
      args.should have_key(:namespace)

      args.fetch(:bucket).should == 'bucket-name-in-fixture-config'
      args.fetch(:build_number).should == build_number
      args.fetch(:namespace).should == book_repo_name
    end

    command.run [build_number]
  end

  context 'when missing aws credentials' do
    let(:aws_credentials) { {} }

    it 'logs a "key not found" error' do
      expect {
        command.run build_number
      }.to raise_error(Cli::CredentialKeyError)
    end
  end

  context 'when missing cf credentials' do
    let(:cf_credentials) { {} }

    it 'raises a "key not found" error' do
      GreenBuildRepository.any_instance.stub(:download)

      expect {
        command.run build_number
      }.to raise_error(Cli::CredentialKeyError)
    end
  end
end
