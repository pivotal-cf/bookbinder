require 'spec_helper'

require './master_middleman/bookbinder_helpers'

describe Navigation::HelperMethods do
  describe '#yield_for_code_snippet' do
    let(:yielded_snippet) do
      class Foo
        include Navigation::HelperMethods
      end

      Foo.new.yield_for_code_snippet(from: repo, at: excerpt_mark)
    end

    let(:repo) { 'fantastic/code-example-repo' }
    let(:excerpt_mark) { 'complicated_function' }

    before { stub_github_for repo }

    it 'returns markdown' do
      markdown_snippet = <<-MARKDOWN
```
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
```
      MARKDOWN
      yielded_snippet.should == markdown_snippet.chomp
    end
  end
end