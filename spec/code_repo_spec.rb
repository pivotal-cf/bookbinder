require 'spec_helper'

describe CodeRepo do
  describe '.get_instance' do
    let(:local_repo_dir) { '/dev/null' }
    before do
      stub_github_for 'foo/book'
      stub_github_for 'foo/dogs-repo'
    end

    context 'when called more than once' do
      it 'always returns the same instance for the same arguments' do
        first_instance = CodeRepo.get_instance('foo/book', local_repo_dir)
        second_instance = CodeRepo.get_instance('foo/book', local_repo_dir)
        expect(first_instance).to be(second_instance)
      end

      it 'returns different instances for different repo names' do
        first_instance = CodeRepo.get_instance('foo/dogs-repo', local_repo_dir)
        second_instance = CodeRepo.get_instance('foo/book', local_repo_dir)

        expect(first_instance).not_to be(second_instance)
      end

      it 'returns different instances for different modes' do
        local_code_repo = CodeRepo.get_instance('foo/book', 'spec/fixtures/repositories')
        remote_code_repo = CodeRepo.get_instance('foo/book', nil)

        expect(local_code_repo).not_to be(remote_code_repo)
      end
    end

    context 'in local mode' do
      context 'if the repo is present, locally' do
        let(:local_repo_dir) { 'spec/fixtures/repositories' }

        it 'copies repos from local directory' do
          expect(CodeRepo.get_instance('foo/code-example-repo', local_repo_dir)).to be_copied
        end
      end

      context 'if the repo is missing' do
        let(:local_repo_dir) { '/dev/null' }

        it 'logs a warning' do
          expect(BookbinderLogger).to receive(:log).with /skipping \(not found\)/
          CodeRepo.get_instance('foo/definitely-not-around', local_repo_dir)
        end
      end
    end
  end

  describe '#get_snippet_and_language_at' do
    let(:constituent) { {'github_repo' => 'my-docs-org/code-example-repo'} }
    before { stub_github_for 'my-docs-org/code-example-repo' }
    let(:repo) { CodeRepo.from_remote(repo_hash: constituent, destination_dir: Dir.mktmpdir) }

    it 'produces a string for the given excerpt_marker' do
      code_snippet = <<-RUBY
fib = Enumerator.new do |yielder|
  i = 0
  j = 1
  loop do
    i, j = j, i + j
    yielder.yield i
  end
end

p fib.take_while { |n| n <= 4E6 }
# => [1, 1, 2 ... 1346269, 2178309, 3524578]
      RUBY

      snippet_from_repo, language = repo.get_snippet_and_language_at('complicated_function')
      expect(snippet_from_repo).to eq(code_snippet.chomp)
      expect(language).to eq('ruby')
    end

    context 'when the snippet is not found' do
      it 'raises an InvalidSnippet error' do
        expect { repo.get_snippet_and_language_at('missing_snippet') }.to raise_exception(CodeRepo::InvalidSnippet)
      end
    end

    context 'when the repo was not copied' do
      let(:missing_repo) { CodeRepo.get_instance('foo/missing-book', '/dev/null') }

      it 'logs a warning' do
        expect(BookbinderLogger).to receive(:log).with /skipping \(not found\)/
        missing_repo.get_snippet_and_language_at('anything_at_all')
      end
    end
  end
end
