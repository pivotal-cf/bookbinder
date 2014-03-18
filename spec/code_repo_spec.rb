require 'spec_helper'

describe CodeRepo do
  describe '#get_snippet_and_language_at' do
    let(:repo_name) { 'my-docs-org/code-example-repo' }
    before { stub_github_for repo_name }
    let(:repo) { CodeRepo.get_instance({'github_repo' => repo_name}) }

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

    context 'when the snippet has an invalid start tag' do
      it 'fails with a warning' do
        expect { repo.get_snippet_and_language_at('bad_start_tag') }.to raise_exception(CodeRepo::InvalidSnippet)
      end
    end

    context 'when the snippet has an invalid end tag' do
      it 'fails with a warning' do
        expect { repo.get_snippet_and_language_at('bad_end_tag') }.to raise_exception(CodeRepo::InvalidSnippet)
      end
    end

    context 'when the repo was not copied' do
      let(:missing_repo) { CodeRepo.get_instance({'github_repo' => 'foo/missing-book'}, '/dev/null') }

      it 'logs a warning' do
        expect(BookbinderLogger).to receive(:log).with /skipping \(not found\)/
        missing_repo.get_snippet_and_language_at('anything_at_all')
      end
    end
  end
end
