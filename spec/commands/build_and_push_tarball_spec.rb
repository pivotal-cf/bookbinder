require 'spec_helper'

describe Cli::BuildAndPushTarball do
  include_context 'tmp_dirs'

  let(:build_and_push_tarball_command) { Cli::BuildAndPushTarball.new(config) }
  let(:build_number) { '17' }
  let(:book_repo) { 'org/fixture-book-title' }

  let(:aws_hash) do
    {
      'aws' => {
        'green_builds_bucket' => bucket,
        'access_key' => access_key,
        'secret_key' => secret_key,
      }
    }
  end

  let(:config_hash) do
    {
      'book_repo' => book_repo,
      'cred_repo' => 'some/repo'
    }
  end
  let(:config) { Configuration.new(config_hash) }

  before do
    ENV.stub(:[])
    ENV.stub(:[]).with('BUILD_NUMBER').and_return(build_number)
    fake_creds = double
    fake_creds.stub(:credentials).and_return(aws_hash)
    CredentialProvider.stub(:new).and_return(fake_creds)
  end

  let(:access_key) { 'access-key' }
  let(:secret_key) { 'secret-key' }
  let(:bucket) { 'bucket-name-in-fixture-config' }

  it 'should call GreenBuildRepository#create with correct parameters' do
    Archive.should_receive(:new).with(key: access_key, secret: secret_key).and_call_original
    Archive.any_instance.should_receive(:create_and_upload_tarball) do |args|
      args.should have_key(:build_number)
      args.should have_key(:bucket)
      args.should have_key(:namespace)

      args.fetch(:bucket).should == bucket
      args.fetch(:build_number).should == build_number
      args.fetch(:namespace).should == 'fixture-book-title'
    end

    build_and_push_tarball_command.run []
  end
end
