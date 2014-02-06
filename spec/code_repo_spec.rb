require 'spec_helper'

describe CodeRepo do
  describe '.get_instance' do
    before do
      stub_github_for 'foo/book'
      stub_github_for 'foo/dogs-repo'
    end

    context 'when called more than once' do
      it 'always returns the same instance' do
        CodeRepo.get_instance('foo/book').object_id
          .should == CodeRepo.get_instance('foo/book').object_id

        CodeRepo.get_instance('foo/dogs-repo').object_id
          .should_not == CodeRepo.get_instance('foo/book').object_id
      end
    end
  end

  describe '#get_snippet_at' do
    let(:constituent) { {'github_repo' => 'my-docs-org/code-example-repo'} }

    before do
      stub_github_for 'my-docs-org/code-example-repo'
    end

    it 'produces a string for the given excerpt_marker' do
      repo = CodeRepo.from_remote(repo_hash: constituent, destination_dir: Dir.mktmpdir)
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

      snippet_from_repo = repo.get_snippet_at('complicated_function')
      snippet_from_repo.should eq(code_snippet.chomp)
    end

    context 'when the snippet is not found' do
      it 'raises an InvalidSnippet error' do
        repo = CodeRepo.from_remote(repo_hash: constituent, destination_dir: Dir.mktmpdir)
        expect { repo.get_snippet_at('missing_snippet') }.to raise_exception(CodeRepo::InvalidSnippet)
      end
    end
  end
end