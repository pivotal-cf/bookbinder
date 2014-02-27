require 'spec_helper'

describe Cli::PushToProd do
  include_context 'tmp_dirs'

  let(:build_number) { '17' }
  around_with_fixture_repo do |spec|
    spec.run
  end

  before do
    CredRepo.any_instance.stub(:credentials) do
      {
        'aws' => {
          'access_key' => 'something',
          'secret_key' => 'something-else',
          'green_builds_bucket' => 'bucket-name-in-fixture-config'
        },
        'cloud_foundry' => {
          'api_endpoint' => 'http://get.your.apis.here.io',
          'production_host' => 'http://get.your.apis.here.io',
          'organization' => 'foooo',
          'production_space' => 'foooo',
          'app_name' => 'foooo',
        }
      }
    end
  end

  it 'should call GreenBuildRepository#download with correct parameters' do
    GreenBuildRepository.any_instance.should_receive(:download) do |args|
      args.should have_key(:download_dir)
      args.should have_key(:bucket)
      args.should have_key(:build_number)
      args.should have_key(:namespace)

      args.fetch(:bucket).should == 'bucket-name-in-fixture-config'
      args.fetch(:build_number).should == build_number
      args.fetch(:namespace).should == 'fixture-book-title'
    end

    Cli::PushToProd.new.run [build_number]
  end

  context 'when missing credentials' do
    before do
      File.stub(:read)
      YAML.stub(:load).and_return({foo: 'bar'})
    end

    it 'logs a "key not found" error' do
      expect(BookbinderLogger).to receive(:log).with(/key.*not found.*in credentials/)
      Cli::PushToProd.new.run build_number
    end
  end
end
