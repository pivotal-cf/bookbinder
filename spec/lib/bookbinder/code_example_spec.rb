require_relative '../../../lib/bookbinder/repositories/section_repository'
require_relative '../../../lib/bookbinder/code_example'
require_relative '../../helpers/nil_logger'
require_relative '../../helpers/spec_git_accessor'

module Bookbinder
  describe CodeExample do
    describe '#get_snippet_and_language_at' do
      let(:repo_name) { 'my-docs-org/code-example-repo' }
      let(:logger) { NilLogger.new }
      let(:repository) {
        Repositories::SectionRepository.new(
          logger,
          store: {},
          build: ->(*args) { CodeExample.new(*args) }
        )
      }

      it 'produces a string for the given excerpt_marker' do
        destination_dir = File.expand_path('../../../fixtures/repositories/code-example-repo', __FILE__)
        vcs_repo = double("vcs_repo", path_to_local_repo: 'my/local_repo', copied?: true, copied_to: destination_dir, full_name: destination_dir)
        code_example = repository.get_instance({'repository' => {'name' => repo_name}},
                                               vcs_repo: vcs_repo)
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
          destination_dir = File.expand_path('../../../fixtures/repositories/code-example-repo', __FILE__)
          vcs_repo = double("vcs_repo", path_to_local_repo: 'my/local_repo', copied?: true, copied_to: destination_dir, full_name: destination_dir)
          code_example = repository.get_instance({'repository' => {'name' => repo_name}},
                                                 vcs_repo: vcs_repo)

          expect { code_example.get_snippet_and_language_at('missing_snippet') }.to raise_exception(CodeExample::InvalidSnippet)
        end
      end

      context 'when the snippet has an invalid start tag' do
        it 'fails with a warning' do
          destination_dir = File.expand_path('../../../fixtures/repositories/code-example-repo', __FILE__)
          vcs_repo = double("vcs_repo", path_to_local_repo: 'my/local_repo', copied?: true, copied_to: destination_dir, full_name: destination_dir)
          code_example = repository.get_instance({'repository' => {'name' => repo_name}},
                                                 vcs_repo: vcs_repo)

          expect { code_example.get_snippet_and_language_at('bad_start_tag') }.to raise_exception(CodeExample::InvalidSnippet)
        end
      end

      context 'when the snippet has an invalid end tag' do
        it 'fails with a warning' do
          destination_dir = File.expand_path('../../../fixtures/repositories/code-example-repo', __FILE__)
          vcs_repo = double("vcs_repo", path_to_local_repo: 'my/local_repo', copied?: true, copied_to: destination_dir, full_name: destination_dir)
          code_example = repository.get_instance({'repository' => {'name' => repo_name}},
                                                 vcs_repo: vcs_repo)

          expect { code_example.get_snippet_and_language_at('bad_end_tag') }.to raise_exception(CodeExample::InvalidSnippet)
        end
      end

      context 'when the repo was not copied' do
        it 'logs a warning' do
          destination_dir = File.expand_path('../../../fixtures/repositories/code-example-repo', __FILE__)
          vcs_repo = double("vcs_repo", path_to_local_repo: 'my/local_repo', copied?: false,
                            announce_skip: nil)

          missing_repo = repository.get_instance({'repository' => {'name' => 'foo/missing-book'}},
                                                 vcs_repo: vcs_repo)

          expect(vcs_repo).to receive(:announce_skip)
          missing_repo.get_snippet_and_language_at('anything_at_all')
        end
      end
    end
  end
end
