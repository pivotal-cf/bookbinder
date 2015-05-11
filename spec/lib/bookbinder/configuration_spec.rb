require_relative '../../../lib/bookbinder/configuration'

module Bookbinder
  describe Configuration do
    it "can return fully formed git URLs, defaulting to GitHub" do
      config = Configuration.new(
        'book_repo' => 'some-org/some-repo',
        'cred_repo' => 'git@bitbucket.org:my/private-cred-repo',
        'sections' => [
          {'repository' => {'name' => 'must/be-github'}},
          {'repository' => {'name' => 'git@bitbucket.org:another/bitbucket-repo'}},
          {'repository' => {'name' => 'https://github.com/over/https'}},
        ],
      )
      expect(config.book_repo_url).to eq("git@github.com:some-org/some-repo")
      expect(config.cred_repo_url).to eq("git@bitbucket.org:my/private-cred-repo")
      expect(config.sections[0].fetch('repo_url')).to eq('git@github.com:must/be-github')
      expect(config.sections[1].fetch('repo_url')).to eq('git@bitbucket.org:another/bitbucket-repo')
      expect(config.sections[2].fetch('repo_url')).to eq('https://github.com/over/https')

      expect(Configuration.new('book_repo' => 'git@amazon.place:some-org/some-repo').book_repo_url).
        to eq('git@amazon.place:some-org/some-repo')
    end

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

    it 'returns nil when optional keys do not exist' do
      config = Configuration.new({})
      expect(config.archive_menu).to be_nil
    end

    it 'returns an empty hash when template_variables is not provided' do
      config = Configuration.new({})
      expect(config.template_variables).to eq({})
    end

    describe 'equality' do
      it 'is true for identical configurations' do
        expect(Configuration.new('a' => 'b', c: 'd')).to eq(Configuration.new('a' => 'b', c: 'd'))
      end

      it 'is false for different configurations' do
        expect(Configuration.new('a' => 'b', c: 'd')).not_to eq(Configuration.new('a' => 'b', c: 'e'))
      end
    end

    it 'can report on whether options are available' do
      config = Configuration.new('foo' => 'bar')
      expect(config).to have_option('foo')
      expect(config).not_to have_option('bar')
    end
  end
end
