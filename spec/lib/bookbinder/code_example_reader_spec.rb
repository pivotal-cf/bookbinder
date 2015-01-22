require_relative '../../../lib/bookbinder/code_example_reader'
require_relative '../../helpers/nil_logger'

module Bookbinder
  describe CodeExampleReader do
    describe '#get_snippet_and_language_at' do
      let(:repo_name) { 'my-docs-org/code-example-repo' }
      let(:logger) { NilLogger.new }
      let(:code_example_reader) { CodeExampleReader.new(logger) }

      it 'produces a string for the given excerpt_marker' do
        destination_dir = File.expand_path('../../../fixtures/repositories/code-example-repo', __FILE__)
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

        snippet_from_repo, language =  code_example_reader.get_snippet_and_language_at('complicated_function', destination_dir, true, 'code-example-repo')
        expect(snippet_from_repo).to eq(code_snippet.chomp)
        expect(language).to eq('ruby')
      end

      context 'when the snippet is not found' do
        it 'raises an InvalidSnippet error' do
          destination_dir = File.expand_path('../../../fixtures/repositories/code-example-repo', __FILE__)

          expect { code_example_reader.get_snippet_and_language_at('missing_snippet', destination_dir, true, 'code-example-repo') }.to raise_exception(CodeExampleReader::InvalidSnippet)
        end
      end

      context 'when the snippet has an invalid start tag' do
        it 'fails with a warning' do
          destination_dir = File.expand_path('../../../fixtures/repositories/code-example-repo', __FILE__)

          expect {
            code_example_reader.get_snippet_and_language_at('bad_start_tag', destination_dir, true, 'code-example-repo')
          }.to raise_exception(CodeExampleReader::InvalidSnippet)
        end
      end

      context 'when the snippet has an invalid end tag' do
        it 'fails with a warning' do
          destination_dir = File.expand_path('../../../fixtures/repositories/code-example-repo', __FILE__)

          expect {
            code_example_reader.get_snippet_and_language_at('bad_end_tag', destination_dir, true, 'code-example-repo')
          }.to raise_exception(CodeExampleReader::InvalidSnippet)
        end
      end

      context 'when the repo was not copied' do
        it 'logs a warning' do
          destination_dir = File.expand_path('../../../fixtures/repositories/code-example-repo', __FILE__)
          expect(logger).to receive(:log).with /skipping \(not found\)/
          code_example_reader.get_snippet_and_language_at('anything_at_all', destination_dir, false, 'code-example-repo')
        end
      end
    end

  end
end