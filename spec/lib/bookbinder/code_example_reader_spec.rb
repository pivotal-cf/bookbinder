require_relative '../../../lib/bookbinder/code_example_reader'
require_relative '../../../lib/bookbinder/ingest/working_copy'

module Bookbinder
  describe CodeExampleReader do
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

      working_copy = Ingest::WorkingCopy.new(copied_to: destination_dir, full_name: 'code-example-repo')
      snippet_from_repo, language =
        CodeExampleReader.new({}).get_snippet_and_language_at('complicated_function', working_copy)
      expect(snippet_from_repo).to eq(code_snippet.chomp)
      expect(language).to eq('ruby')
    end

    context 'when the snippet is not found' do
      it 'raises an InvalidSnippet error' do
        destination_dir = File.expand_path('../../../fixtures/repositories/code-example-repo', __FILE__)
        working_copy = Ingest::WorkingCopy.new(copied_to: destination_dir, full_name: 'code-example-repo')

        expect { CodeExampleReader.new({}).get_snippet_and_language_at('missing_snippet', working_copy) }.
          to raise_exception(CodeExampleReader::InvalidSnippet)
      end
    end

    context 'when the snippet has an invalid start tag' do
      it 'fails with a warning' do
        destination_dir = File.expand_path('../../../fixtures/repositories/code-example-repo', __FILE__)
        working_copy = Ingest::WorkingCopy.new(copied_to: destination_dir, full_name: 'code-example-repo')

        expect {
          CodeExampleReader.new({}).get_snippet_and_language_at('bad_start_tag', working_copy)
        }.to raise_exception(CodeExampleReader::InvalidSnippet)
      end
    end

    context 'when the snippet has an invalid end tag' do
      it 'fails with a warning' do
        destination_dir = File.expand_path('../../../fixtures/repositories/code-example-repo', __FILE__)
        working_copy = Ingest::WorkingCopy.new(copied_to: destination_dir, full_name: 'code-example-repo')

        expect {
          CodeExampleReader.new({}).get_snippet_and_language_at('bad_end_tag', working_copy)
        }.to raise_exception(CodeExampleReader::InvalidSnippet)
      end
    end

    context 'when the repo was not copied' do
      it 'logs a warning' do
        out = StringIO.new
        working_copy = Ingest::WorkingCopy.new(copied_to: nil, full_name: 'code-example-repo')
        CodeExampleReader.new(out: out).get_snippet_and_language_at('can_be_anything', working_copy)
        expect(out.tap(&:rewind).read).to eq('  skipping (not found) code-example-repo')
      end
    end

    context 'when there is no language specified' do
      it 'returns a nil language :(' do
        destination_dir = File.expand_path('../../../fixtures/repositories/code-example-repo', __FILE__)
        working_copy = Ingest::WorkingCopy.new(copied_to: destination_dir, full_name: 'code-example-repo')
        snippet_from_repo, language =
          CodeExampleReader.new({}).get_snippet_and_language_at('typeless_stuff', working_copy)
        expect(language).to be_nil
      end
    end
  end
end
