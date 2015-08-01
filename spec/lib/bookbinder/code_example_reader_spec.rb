require_relative '../../../lib/bookbinder/code_example_reader'
require_relative '../../../lib/bookbinder/ingest/working_copy'

module Bookbinder
  describe CodeExampleReader do
    let(:working_copy) { Ingest::WorkingCopy.new(copied_to: 'my/dir', full_name: 'code-example-repo') }

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

      found_text = <<-RUBY
# code_snippet complicated_function start ruby
#{code_snippet}



# code_snippet complicated_function end
      RUBY

      fs = instance_double('Bookbinder::LocalFileSystemAccessor')

      allow(fs).to receive(:find_lines_recursively).with(
        working_copy.path,
        /code_snippet complicated_function start.*code_snippet complicated_function end/m
      ) { found_text }

      snippet_from_repo, language =
        CodeExampleReader.new({}, fs).get_snippet_and_language_at('complicated_function', working_copy)

      expect(snippet_from_repo).to eq(code_snippet.chomp)
      expect(language).to eq('ruby')
    end

    context 'when the snippet is not found' do
      it 'raises an InvalidSnippet error' do
        fs = instance_double('Bookbinder::LocalFileSystemAccessor')
        allow(fs).to receive(:find_lines_recursively) { "" }
        expect { CodeExampleReader.new({}, fs).get_snippet_and_language_at('missing_snippet', working_copy) }.
          to raise_exception(CodeExampleReader::InvalidSnippet)
      end
    end

    context 'when the repo was not copied' do
      let(:working_copy) { Ingest::WorkingCopy.new(copied_to: nil, full_name: 'code-example-repo') }

      it 'logs a warning' do
        out = StringIO.new
        fs = instance_double('Bookbinder::LocalFileSystemAccessor')
        CodeExampleReader.new({out: out}, fs).get_snippet_and_language_at('can_be_anything', working_copy)
        expect(out.tap(&:rewind).read).to eq('  skipping (not found) code-example-repo')
      end
    end

    context 'when there is no language specified' do
      it 'returns a nil language :(' do
        fs = instance_double('Bookbinder::LocalFileSystemAccessor')
        allow(fs).to receive(:find_lines_recursively) { "# code_snippet typeless_stuff\n" }
        snippet_from_repo, language =
          CodeExampleReader.new({}, fs).get_snippet_and_language_at('typeless_stuff', working_copy)
        expect(language).to be_nil
      end
    end
  end
end
