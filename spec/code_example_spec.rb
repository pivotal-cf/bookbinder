require 'spec_helper'

module Bookbinder
  describe CodeExample do
    describe '#get_snippet_and_language_at' do
      let(:repo_name) { 'my-docs-org/code-example-repo' }
      let(:logger) { NilLogger.new }
      let(:git_client) { GitClient.new(logger) }
      let(:code_example) { CodeExample.get_instance(logger, section_hash: {'repository' => {'name' => repo_name}}) }

      before do
        stub_github_for git_client, repo_name
        allow(GitClient).to receive(:new).and_return(git_client)
      end

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

        snippet_from_repo, language = code_example.get_snippet_and_language_at('complicated_function')
        expect(snippet_from_repo).to eq(code_snippet.chomp)
        expect(language).to eq('ruby')
      end

      context 'when the snippet is not found' do
        it 'raises an InvalidSnippet error' do
          expect { code_example.get_snippet_and_language_at('missing_snippet') }.to raise_exception(CodeExample::InvalidSnippet)
        end
      end

      context 'when the snippet has an invalid start tag' do
        it 'fails with a warning' do
          expect { code_example.get_snippet_and_language_at('bad_start_tag') }.to raise_exception(CodeExample::InvalidSnippet)
        end
      end

      context 'when the snippet has an invalid end tag' do
        it 'fails with a warning' do
          expect { code_example.get_snippet_and_language_at('bad_end_tag') }.to raise_exception(CodeExample::InvalidSnippet)
        end
      end

      context 'when the repo was not copied' do
        let(:missing_repo) { CodeExample.get_instance(logger, section_hash: {'repository' => {'name' => 'foo/missing-book'}}, local_repo_dir: '/dev/null') }

        it 'logs a warning' do
          allow(logger).to receive(:log)
          expect(logger).to receive(:log).with /skipping \(not found\)/
          missing_repo.get_snippet_and_language_at('anything_at_all')
        end
      end
    end
  end
end