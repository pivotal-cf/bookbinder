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
    let(:markdown_snippet) do
      <<-MARKDOWN
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
    end
    let(:repo) { 'fantastic/code-example-repo' }
    let(:excerpt_mark) { 'complicated_function' }

    it 'returns markdown' do
      stub_github_for repo
      yielded_snippet.should == markdown_snippet.chomp
    end
  end

  describe '#yield_for_subnav' do
    pending
  end

  describe '#breadcrumbs' do
    include_context 'tmp_dirs'

    before do
      FileUtils.cp_r 'master_middleman/.', tmpdir
      FileUtils.mkdir_p source_dir
      squelch_middleman_output
      write_markdown_source_file source_file_under_test, source_file_title, source_file_content, breadcrumb_title
    end

    let(:source_dir) { tmp_subdir 'source' }
    let(:source_file_content) { '<%= breadcrumbs %>' }
    let(:breadcrumb_title) { nil }

    context 'when invoked in the top-level index file' do
      let(:source_file_under_test) { 'index.md.erb' }
      let(:source_file_title) { 'Dogs' }
      let(:output) { File.read File.join(tmpdir, 'build', 'index.html') }

      it 'displays nothing' do
        run_middleman
        expect(output).to be_empty
      end
    end

    context 'when invoked in an index file in a sub-dir, when the parent has a title' do
      let(:source_file_under_test) { File.join('big-dogs', 'index.md.erb') }
      let(:source_file_title) { 'Big Dogs' }
      let(:output) { File.read File.join(tmpdir, 'build', 'big-dogs', 'index.html') }

      before do
        write_markdown_source_file 'index.md.erb', 'Dogs'
      end

      it 'creates a two level breadcrumb' do
        run_middleman
        doc = Nokogiri::HTML(output)
        expect(doc.css('ul li').length).to eq(2)
      end

      it 'creates entries for each level of the hierarchy' do
        run_middleman
        doc = Nokogiri::HTML(output)
        expect(doc.css('ul li')[0].text).to eq('Dogs')
        expect(doc.css('ul li')[1].text).to eq('Big Dogs')
      end

      it 'gives the last entry an "active" class' do
        run_middleman
        doc = Nokogiri::HTML(output)
        expect(doc.css('ul li')[0]['class']).to be_nil
        expect(doc.css('ul li')[1]['class']).to eq('active')
      end

      context 'when the parent also has a breadcrumb title' do
        let(:breadcrumb_title) { 'Fancy Schmancy New Title' }
        it 'uses the breadcrumb title instead of the title' do
          run_middleman
          doc = Nokogiri::HTML(output)
          expect(doc.css('ul li')[0].text).to eq('Dogs')
          expect(doc.css('ul li')[1].text).to eq('Fancy Schmancy New Title')
        end
      end
    end

    context 'when invoked in an index file in a sub-dir, when the parent is not markdown' do
      let(:source_file_under_test) { File.join('big-dogs', 'index.md.erb') }
      let(:source_file_title) { 'Big Dogs' }
      let(:output) { File.read File.join(tmpdir, 'build', 'big-dogs', 'index.html') }

      before do
        full_path = File.join(source_dir, 'index.md.erb')
        File.open(full_path, 'w') { |f| f.write('<html><head><title>Dogs</title></head><body>Dogs are great!</body></html>') }
      end

      it 'does not create a breadcrumb' do
        run_middleman
        doc = Nokogiri::HTML(output)
        expect(doc.css('ul li').length).to eq(0)
      end
    end
  end

  describe '#vars' do
    include_context 'tmp_dirs'

    before do
      FileUtils.cp_r File.join('master_middleman/.'), tmpdir
      FileUtils.mkdir_p source_dir
      squelch_middleman_output
      write_markdown_source_file source_file_under_test, source_file_title, source_file_content
    end

    let(:source_dir) { tmp_subdir 'source' }
    let(:source_file_content) { '<%= vars.var_name %>' }

    context 'when the variable is defined' do
      let(:source_file_under_test) { 'index.md.erb' }
      let(:source_file_title) { 'Dogs' }
      let(:output) { File.read File.join(tmpdir, 'build', 'index.html') }

      it 'displays nothing' do
        run_middleman 'var_name' => 'A Variable Value'
        expect(output).to include('A Variable Value')
      end
    end
  end

  describe '#quick_links' do
    pending
  end
end
