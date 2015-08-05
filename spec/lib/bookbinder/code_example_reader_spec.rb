require_relative '../../../lib/bookbinder/code_example_reader'
require_relative '../../../lib/bookbinder/ingest/working_copy'

module Bookbinder
  describe CodeExampleReader do
    let(:working_copy) { Ingest::WorkingCopy.new(copied_to: 'my/dir', full_name: 'code-example-repo') }

    it 'produces a string for the given excerpt_marker, without choking on binary files' do
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
      path_to_binary_file = File.absolute_path('../../../fixtures/binary_file', __FILE__)

      allow(fs).to receive(:find_files_recursively).with(
        working_copy.path,
      ) { %w(foo bar baz) }
      allow(fs).to receive(:read).with("foo") { File.read(path_to_binary_file) }
      allow(fs).to receive(:read).with("bar").and_return(<<-DOC)
prologue
#{found_text}
epilogue
      DOC

      snippet_from_repo, language =
        CodeExampleReader.new({}, fs).get_snippet_and_language_at('complicated_function', working_copy)

      expect(snippet_from_repo).to eq(code_snippet.chomp)
      expect(language).to eq('ruby')
    end

    context 'when the snippet is not found' do
      it 'raises an InvalidSnippet error' do
        fs = instance_double('Bookbinder::LocalFileSystemAccessor')
        allow(fs).to receive(:find_files_recursively) { ["foo"] }
        allow(fs).to receive(:read).with("foo") { "asdf" }
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
        allow(fs).to receive(:find_files_recursively) { %w(foo) }
        allow(fs).to receive(:read).with("foo") { "# code_snippet typeless_stuff start\n# code_snippet typeless_stuff end\n" }
        snippet_from_repo, language =
          CodeExampleReader.new({}, fs).get_snippet_and_language_at('typeless_stuff', working_copy)
        expect(language).to be_nil
      end
    end

    it "isn't susceptible to regexp injection" do
      require 'timeout'

      found_text = <<-RUBY
# code_snippet aaaaaaaaaaaaaaaaaaaaaaaa start
some stuff
# code_snippet aaaaaaaaaaaaaaaaaaaaaaaa end
      RUBY

      fs = instance_double('Bookbinder::LocalFileSystemAccessor')

      allow(fs).to receive(:find_files_recursively) { ["foo"] }
      allow(fs).to receive(:read).with("foo") { found_text }

      expect {
        Timeout::timeout(2) {
          CodeExampleReader.new({}, fs).get_snippet_and_language_at('(.*a){11}', working_copy)
        }
      }.to raise_error(CodeExampleReader::InvalidSnippet)
    end
  end
end
