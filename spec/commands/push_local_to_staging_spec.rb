require 'spec_helper'

describe Cli::PushLocalToStaging do
  let(:cred_repo) { 'some-repo' }
  let(:config_hash) do
    {
      'cred_repo' => cred_repo
    }
  end

  let(:credentials) do
    {
      'cloud_foundry' => {
        'api_endpoint' => 'end',
        'staging_host' => 'host',
        'organization' => 'org',
        'staging_space' => 'space',
        'app_name' => 'app',
        'username' => 'user',
        'password' => 'pass',
      }
    }
  end

  let(:fake_cred_repo) { double(credentials: credentials) }
  let(:fake_pusher) { double }
  let(:config) { Configuration.new(config_hash) }

  before do
    CredRepo.stub(:new).and_return(fake_cred_repo)
  end

  it 'calls Pusher#push with CF credentials' do
    Pusher.stub(:new).and_return(fake_pusher)
    expect(fake_pusher).to receive(:push).with(*%w[end host org space app ./final_app user pass])
    Cli::PushLocalToStaging.new(config).run(nil)
  end

  it 'returns 0' do
    expect(Cli::PushLocalToStaging.new(config).run(nil)).to eq(0)
  end
end
