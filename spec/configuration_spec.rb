require 'spec_helper'

describe Configuration do
  let(:config_hash) do
    {
      meat: 'balogna',
      'first_name' => 'oscar',
      last_name: 'meyer',
      cred_repo: 'owner/place'
    }
  end

  let(:config) { Configuration.new(config_hash) }

  describe 'fetching values' do
    context 'when the key exists' do
      it 'has a method that returns the value for a symbol key' do
        expect(config.meat).to eq('balogna')
      end

      it 'has a method that returns the value for a string key' do
        expect(config.first_name).to eq('oscar')
      end
    end

    context 'when the key does not exist' do
      it 'raises' do
        expect {
          config.johnsonville_brats
        }.to raise_error(KeyError)
      end
    end
  end

  describe '#respond_to?' do
    context 'for a key that exists' do
      it 'is true' do
        expect(config.respond_to?(:last_name)).to be_true
        expect(config.respond_to?(:aws_credentials)).to be_true
      end
    end

    context 'for a key that does not exist' do
      it 'is false' do
        expect(config.respond_to?(:johnsonville_brats)).to be_false
      end
    end
  end

  describe 'credentials' do
    let(:aws_hash) { {secret: 'some-secret', agent: 'wow-agent'} }
    let(:cf_hash) { {cf_secret: 'some-cf-secret', agent: 'wow-cf-agent'} }
    let(:creds_hash) { { 'aws' => aws_hash, 'cloud_foundry' => cf_hash } }
    let(:cred_repo) { double }

    before do
      cred_repo.stub(:credentials).and_return(creds_hash)
      CredRepo.stub(:new).with(full_name: 'owner/place').and_return(cred_repo)
    end

    describe '#aws_credentials' do
      it 'returns a Configuration with the AWS credentials from the credentials repository' do
        aws_hash.keys.each do |k|
          expect(config.aws_credentials.send(k)).to eq(aws_hash[k])
        end
      end
    end

    describe '#cloud_foundry_credentials' do
      it 'returns a Configuration with the AWS credentials from the credentials repository' do
        cf_hash.keys.each do |k|
          expect(config.cf_credentials.send(k)).to eq(cf_hash[k])
        end
      end
    end

    it 'fetches the credentials repository only when the credentials are asked for' do
      config.last_name
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
