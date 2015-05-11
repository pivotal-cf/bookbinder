require_relative '../../../lib/bookbinder/configuration'
require_relative '../../helpers/nil_logger'

module Bookbinder
  describe Configuration do
    let(:bookbinder_schema_version) { '1.0.0' }
    let(:logger) { NilLogger.new }
    let(:user_schema_version) { '1.0.0' }
    let(:archive_menu) { [] }
    let(:config_hash) do
      {
          'book_repo' => 'some-org/some-repo',
          'versions' => %w(v1.7.1.9 redacted v3),
          'cred_repo' => 'some-org/cred-repo',
          'layout_repo' => 'some-org/some-repo',
          'sections' => ['section1', 'section2'],
          'public_host' => 'http://www.example.com',
          'template_variables' => {'some-var' => 'some-value'},
          'schema_version' => user_schema_version,
          'archive_menu' => archive_menu
      }
    end

    let(:config) { Configuration.new(config_hash) }

    it "returns an empty collection of versions if none are provided" do
      expect(Configuration.new({}).versions).to be_empty
    end

    it "can merge another config object" do
      expect(Configuration.new('book_repo' => 'foo/bar',
                               'cred_repo' => 'cred/repo').
             merge(Configuration.new('book_repo' => 'baz/qux'))).
        to eq(Configuration.new('book_repo' => 'baz/qux',
                                'cred_repo' => 'cred/repo'))
    end

    it "can merge hashes" do
      expect(Configuration.new('book_repo' => 'foo/bar',
                               'cred_repo' => 'cred/repo').
             merge('book_repo' => 'baz/qux')).
        to eq(Configuration.new('book_repo' => 'baz/qux',
                                'cred_repo' => 'cred/repo'))
    end

    describe 'accessing configuration values' do
      it 'exposes some of these keys' do
        config_hash.delete('schema_version')
        config_hash.each do |key, value|
          expect(config.public_send(key)).to eq value
        end
      end

      context 'when optional keys do not exist' do
        it 'returns nil' do
          config_hash.delete('archive_menu')
          expect(config.public_send('archive_menu')).to be_nil
        end
      end

      it 'returns an empty hash when template_variables is not provided' do
        config_hash.delete('template_variables')
        expect(config.template_variables).to eq({})
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

    describe '#has_option?' do
      let(:config) { Configuration.new('foo' => 'bar') }

      context 'when the configuration has the option' do
        it 'should return true' do
          expect(config.has_option?('foo')).to eq(true)
        end
      end

      context 'when the configuration does not have the option' do
        it 'should return false' do
          expect(config.has_option?('bar')).to eq(false)
        end
      end
    end
  end
end
