require 'spec_helper'

describe Cli::BuildAndPushTarball do
  include_context 'tmp_dirs'

  let(:build_number) { '17' }

  around_with_fixture_repo do |spec|
    spec.run
  end

  before do
    CredRepo.any_instance.stub(:credentials) do
      {
        'aws' => {
          'green_builds_bucket' => bucket,
          'access_key' => access_key,
          'secret_key' => secret_key,
        }
      }
    end

    ENV.stub(:[])
    ENV.stub(:[]).with('BUILD_NUMBER').and_return(build_number)
  end

  let(:access_key) { 'access-key' }
  let(:secret_key) { 'secret-key' }
  let(:bucket) { 'bucket-name-in-fixture-config' }

  it 'should call GreenBuildRepository#create with correct parameters' do
    GreenBuildRepository.should_receive(:new).with(key: access_key, secret: secret_key).and_call_original
    GreenBuildRepository.any_instance.should_receive(:create) do |args|
      args.should have_key(:build_number)
      args.should have_key(:bucket)
      args.should have_key(:namespace)

      args.fetch(:bucket).should == bucket
      args.fetch(:build_number).should == build_number
      args.fetch(:namespace).should == 'fixture-book-title'
    end

    Cli::BuildAndPushTarball.new.run []
  end

  context 'when missing credentials' do
    before do
      CredRepo.any_instance.stub(:credentials) do
        {'aws' => {}}
      end
    end

    it 'raises a CredentialKeyError' do
      ->(){ Cli::BuildAndPushTarball.new.run [] }.should raise_exception(Cli::CredentialKeyError)
    end
  end
end
