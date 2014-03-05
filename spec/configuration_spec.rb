require 'spec_helper'

describe Configuration do
  let(:config_hash) do
    {
      'book_repo' => 'some-org/some-repo',
      'cred_repo' => 'some-org/cred-repo',
      'repos' => [{'github_repo' => 'some-org/some-docs', 'directory' => 'docs'}],
      'public_host' => 'http://www.example.com',
      'template_variables' => {'some-var' => 'some-value'}
    }
  end

  subject(:config) { Configuration.new(config_hash) }

  describe 'accessing configuration values' do
    it 'exposes #book_repo' do
      expect(config.book_repo).to eq('some-org/some-repo')
    end

    it 'exposes #cred_repo' do
      expect(config.cred_repo).to eq('some-org/cred-repo')
    end

    it 'exposes #repos' do
      expect(config.repos).to eq([{'github_repo' => 'some-org/some-docs', 'directory' => 'docs'}])
    end

    it 'exposes #public_host' do
      expect(config.public_host).to eq('http://www.example.com')
    end

    it 'exposes #template_variables' do
      expect(config.template_variables).to eq({'some-var' => 'some-value'})
    end

    it 'returns an empty hash when template_variables is not provided' do
      config_hash.delete('template_variables')
      expect(config.template_variables).to eq({})
    end
  end

  describe 'credentials' do
    let(:aws_hash) { {'access_key' => 'some-secret', 'secret_key' => 'wow-agent', 'green_builds_bucket' => 'its_a_pail'} }
    let(:cf_hash) do
      {
        'api_endpoint' =>'http://some-api-endpoint.example.com',
        'production_host' => 'http://some-prod-host.example.com',
        'production_space' => 'some-prod-space',
        'staging_host' => 'http://some-staging-host.example.com',
        'staging_space' => 'some-staging-space',
        'app_name' => 'some-app',
        'username' => 'some-user',
        'password' => 'some-pass',
        'organization' => 'some-org'
      }
    end
    let(:creds_hash) { { 'aws' => aws_hash, 'cloud_foundry' => cf_hash } }
    let(:cred_repo) { double(credentials: creds_hash) }

    before do
      CredRepo.stub(:new).with(full_name: 'some-org/cred-repo').and_return(cred_repo)
    end

    describe '#aws_credentials' do
      it 'returns a Configuration with the AWS credentials from the credentials repository' do
        expect(config.aws_credentials.access_key).to eq('some-secret')
        expect(config.aws_credentials.secret_key).to eq('wow-agent')
        expect(config.aws_credentials.green_builds_bucket).to eq('its_a_pail')
      end
    end

    describe '#cf_credentials' do
      it 'returns a Configuration with the CF credentials from the credentials repository' do
        expect(config.cf_credentials.api_endpoint).to eq('http://some-api-endpoint.example.com')
        expect(config.cf_credentials.production_host).to eq('http://some-prod-host.example.com')
        expect(config.cf_credentials.production_space).to eq('some-prod-space')
        expect(config.cf_credentials.staging_host).to eq('http://some-staging-host.example.com')
        expect(config.cf_credentials.staging_space).to eq('some-staging-space')
        expect(config.cf_credentials.app_name).to eq('some-app')
        expect(config.cf_credentials.username).to eq('some-user')
        expect(config.cf_credentials.password).to eq('some-pass')
        expect(config.cf_credentials.organization).to eq('some-org')
      end

      describe 'default values' do
        it 'defaults production_host to nil' do
          cf_hash.delete('production_host')
          expect(config.cf_credentials.production_host).to be_nil
        end

        it 'defaults production_space to nil' do
          cf_hash.delete('production_space')
          expect(config.cf_credentials.production_space).to be_nil
        end

        it 'defaults username to nil' do
          cf_hash.delete('username')
          expect(config.cf_credentials.username).to be_nil
        end

        it 'defaults password to nil' do
          cf_hash.delete('password')
          expect(config.cf_credentials.password).to be_nil
        end
      end
    end

    it 'fetches the credentials repository only when the credentials are asked for' do
      config.book_repo
      expect(CredRepo).to_not have_received(:new)
      config.aws_credentials
      expect(CredRepo).to have_received(:new)
    end

    it 'only fetches the credentials repository once' do
      expect(CredRepo).to receive(:new).once
      config.aws_credentials
      config.cf_credentials
      config.aws_credentials
    end
  end

  describe 'equality' do
    let(:config_hash_1) do
      { 'a' => 'b', c: 'd'}
    end

    let(:config_hash_2) do
      { 'a' => 'b', c: 'e'}
    end

    it 'is true for identical configurations' do
      expect(Configuration.new(config_hash_1)).to eq(Configuration.new(config_hash_1))
    end

    it 'is false for different configurations' do
      expect(Configuration.new(config_hash_1)).not_to eq(Configuration.new(config_hash_2))
    end
  end
end
