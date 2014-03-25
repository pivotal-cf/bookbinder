require 'spec_helper'

describe Configuration do
  let(:config_hash) do
    {
      'book_repo' => 'some-org/some-repo',
      'cred_repo' => 'some-org/cred-repo',
      'sections' => ['section1', 'section2'],
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

    it 'exposes #sections' do
      expect(config.sections).to eq(['section1', 'section2'])
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
        'api_endpoint' => 'http://some-api-endpoint.example.com',
        'production_host' => 'some-prod-host',
        'production_space' => 'some-prod-space',
        'staging_host' => 'some-staging-host',
        'staging_space' => 'some-staging-space',
        'app_name' => 'some-app',
        'username' => 'some-user',
        'password' => 'some-pass',
        'organization' => 'some-org'
      }
    end
    let(:creds_hash) { {'aws' => aws_hash, 'cloud_foundry' => cf_hash} }
    let(:cred_repo) { double(credentials: creds_hash) }

    before do
      repository = double
      allow(Repository).to receive(:new).with(full_name: 'some-org/cred-repo').and_return(repository)
      allow(CredentialProvider).to receive(:new).with(repository).and_return(cred_repo)
    end

    describe '#aws_credentials' do
      it 'returns a Configuration with the AWS credentials from the credentials repository' do
        expect(config.aws_credentials.access_key).to eq('some-secret')
        expect(config.aws_credentials.secret_key).to eq('wow-agent')
        expect(config.aws_credentials.green_builds_bucket).to eq('its_a_pail')
      end

      it 'memoizes' do
        expect(config.aws_credentials).to equal(config.aws_credentials)
      end
    end

    describe Configuration::AwsCredentials do
      let(:aws_credentials) { Configuration::AwsCredentials.new(aws_hash) }

      it 'raises CredentialKeyError when a required key is missing' do
        aws_hash.clear
        Configuration::AwsCredentials::REQUIRED_KEYS.each do |key|
          expect { aws_credentials.send(key) }.to raise_error(Configuration::CredentialKeyError)
        end
      end
    end

    describe Configuration::CfCredentials do
      let(:is_production) { nil }
      let(:cf_credentials) { Configuration::CfCredentials.new(cf_hash, is_production) }

      it 'returns a Configuration with the CF credentials from the credentials repository' do
        expect(cf_credentials.api_endpoint).to eq('http://some-api-endpoint.example.com')
        expect(cf_credentials.app_name).to eq('some-app')
        expect(cf_credentials.username).to eq('some-user')
        expect(cf_credentials.password).to eq('some-pass')
        expect(cf_credentials.organization).to eq('some-org')
      end

      it 'raises CredentialKeyError when a required key is missing' do
        cf_hash.clear
        methods = Configuration::CfCredentials::REQUIRED_KEYS + [:host, :space]
        methods.each do |key|
          expect { cf_credentials.send(key) }.to raise_error(Configuration::CredentialKeyError)
        end
      end

      it 'memoizes' do
        expect(cf_credentials).to be(cf_credentials)
      end

      describe 'default values' do
        it 'defaults username to nil' do
          cf_hash.delete('username')
          expect(cf_credentials.username).to be_nil
        end

        it 'defaults password to nil' do
          cf_hash.delete('password')
          expect(cf_credentials.password).to be_nil
        end
      end

      describe 'is_production' do
        context 'when production' do
          let(:is_production) { true }

          it 'uses production values for host and space' do
            expect(cf_credentials.host).to eq('some-prod-host')
            expect(cf_credentials.space).to eq('some-prod-space')
          end
        end

        context 'when staging' do
          let(:is_production) { false }

          it 'uses staging values for host and space' do
            expect(cf_credentials.host).to eq('some-staging-host')
            expect(cf_credentials.space).to eq('some-staging-space')
          end
        end
      end
    end

    describe '#cf_production_credentials' do
      describe '#host' do
        it 'is the production host' do
          expect(config.cf_production_credentials.host).to eq('some-prod-host')
        end
      end

      describe '#space' do
        it 'is the production space' do
          expect(config.cf_production_credentials.space).to eq('some-prod-space')
        end
      end
    end

    describe '#cf_staging_credentials' do
      describe '#host' do
        it 'is the staging host' do
          expect(config.cf_staging_credentials.host).to eq('some-staging-host')
        end
      end

      describe '#space' do
        it 'is the staging space' do
          expect(config.cf_staging_credentials.space).to eq('some-staging-space')
        end
      end
    end

    it 'fetches the credentials repository only when the credentials are asked for' do
      config.book_repo
      expect(CredentialProvider).to_not have_received(:new)
      config.aws_credentials
      expect(CredentialProvider).to have_received(:new)
    end

    it 'only fetches the credentials repository once' do
      expect(CredentialProvider).to receive(:new).once
      config.aws_credentials
      config.cf_staging_credentials
      config.cf_production_credentials
      config.aws_credentials
    end
  end

  describe 'equality' do
    let(:config_hash_1) do
      {'a' => 'b', c: 'd'}
    end

    let(:config_hash_2) do
      {'a' => 'b', c: 'e'}
    end

    it 'is true for identical configurations' do
      expect(Configuration.new(config_hash_1)).to eq(Configuration.new(config_hash_1))
    end

    it 'is false for different configurations' do
      expect(Configuration.new(config_hash_1)).not_to eq(Configuration.new(config_hash_2))
    end
  end

  describe 'validity' do
    it 'should be valid when directory names are unique' do
      section1 = {
          'repository' => {
              'name' => 'cloudfoundry/docs-cloudfoundry-concepts'
          },
          'directory' => 'concepts'
      }

      section2 = {
          'repository' => {
              'name' => 'cloudfoundry/docs-cloudfoundry-foo'
          },
          'directory' => 'foo'
      }

      valid_config_hash = {'sections' => [section1, section2]}

      configuration = Configuration.new(valid_config_hash)
      expect(configuration.valid?).to eq(true)
    end

    it 'should be invalid when directory names are not unique' do
      section1 = {
          'repository' => {
              'name' => 'cloudfoundry/docs-cloudfoundry-concepts'
          },
          'directory' => 'concepts'
      }
      invalid_config_hash = {'sections' => [section1, section1]}

      configuration = Configuration.new(invalid_config_hash)
      expect(configuration.valid?).to eq(false)
    end
  end
end
