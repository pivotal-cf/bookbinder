require 'spec_helper'

require './master_middleman/bookbinder_helpers'
require 'redcarpet'

module Bookbinder
  describe Navigation::HelperMethods do
    include_context 'tmp_dirs'

    let(:logger) { NilLogger.new }
    let(:klass) do
      Class.new do
        include Navigation::HelperMethods

        attr_reader :config

        def initialize(config)
          @config = config
        end
      end
    end

    before do
      allow(BookbinderLogger).to receive(:new).and_return(logger)
    end

    def run_middleman(template_variables = {})
      original_mm_root = ENV['MM_ROOT']

      Middleman::Cli::Build.instance_variable_set(:@_shared_instance, nil)
      ENV['MM_ROOT'] = tmpdir
      Dir.chdir(tmpdir) do
        build_command = Middleman::Cli::Build.new [], {:quiet => true}, {}
        Middleman::Cli::Build.shared_instance(false).config[:template_variables] = template_variables
        build_command.invoke :build, [], {:verbose => false}
      end

      ENV['MM_ROOT'] = original_mm_root
    end

    describe '#yield_for_code_snippet' do
      let(:config) { {} }
      let(:yielded_snippet) { klass.new(config).yield_for_code_snippet(from: repo, at: excerpt_mark) }
      let(:markdown_snippet) do
<<-MARKDOWN
```ruby
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

      context 'when not local' do
        let(:config) { {local_repo_dir: nil} }
        let(:git_client) { GitClient.new(logger) }

        before do
          mock_github_for git_client, repo
          allow(GitClient).to receive(:new).and_return(git_client)
        end

        it 'returns markdown from github' do
          expect(yielded_snippet).to eq(markdown_snippet.chomp)
        end
      end

      context 'when local' do
        let(:config) { {local_repo_dir: '..'} }
        around_with_fixture_repo &:run

        it 'returns markdown from the local repo' do
          expect(yielded_snippet).to eq(markdown_snippet.chomp)
        end
      end
    end

    describe '#yield_for_subnav' do
      pending
    end

    describe '#modified_date' do
      subject(:an_instance) { klass.new(config) }

      let(:first_date) { "19 Jan 3028" }
      let(:filename) { "Moon Colonization History" }
      let(:cache) { double('GitModCache') }
      let(:config) { {filecache: cache} }

      before { allow(an_instance).to receive(:current_path).and_return filename }

      context 'when the file is found in the cache' do
        before { allow(cache).to receive(:fetch).with(filename).and_return(first_date) }

        it 'returns the date for that file' do
          expect(an_instance.modified_date).to eq(first_date)
        end
      end

      context 'when the file is not found in the cache' do
        let(:now) { Time.now }
        before { allow(cache).to receive(:fetch).with(filename).and_return(now) }

        it 'returns todays date as the last-modified-date' do
          allow(Time).to receive(:now).and_return(now)

          expect(an_instance.modified_date).to eq(now)
        end
      end

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
      let(:quick_links) do
        allow_any_instance_of(klass).to receive(:current_page).and_return(double(:current_page, source_file: nil))
        klass.new({}).quick_links
      end

      let(:sample_markdown) do
<<MARKDOWN
title: Dummy title
#####

Dummy content

## <a id='target'></a>Target run.pivotal.io ##

## <a id='hug'>Target run.pivotal.io with a hug</a> ##

## <a id='no-closing'></a> No closing octothorpes

## <a id="double-quote"></a> Double quotation

Dummy content

## <a id='sample-apps'></a>Sample Applications ##

  ## <a id='sample-apps'></a>I am not a header, I am indented ##

Dummy content

More dummy content

## <a id='prepare-app'></a>Prepare Your Own Application for Deployment ##
MARKDOWN
      end

      let(:expected_output) do
<<HTML
<div class=\"quick-links\"><ul>
<li><a href=\"#target\">Target run.pivotal.io</a></li>
<li><a href=\"#hug\">Target run.pivotal.io with a hug</a></li>
<li><a href=\"#no-closing\">No closing octothorpes</a></li>
<li><a href=\"#double-quote\">Double quotation</a></li>
<li><a href=\"#sample-apps\">Sample Applications</a></li>
<li><a href=\"#prepare-app\">Prepare Your Own Application for Deployment</a></li>
</ul></div>
HTML
      end

      before do
        expect(File).to receive(:read).and_return(sample_markdown)
      end

      it 'returns a div with all linkable places' do
        expect(quick_links).to eq(expected_output.strip)
      end

      context 'when smaller headers follow larger headers' do
        let(:sample_markdown) do
<<MARKDOWN
## <a id='prepare-app'></a>Prepare Your Own Application for Deployment ##

## <a id='parent'></a>AKA, the Nest ##

### <a id='child'></a>The Nestee ###

### <a id='bro'></a>The Nestee's Brother ###

## <a id='uncle'></a>Not nested ##

MARKDOWN
        end

        let(:expected_output) do
          <<HTML
<div class=\"quick-links\"><ul>
<li><a href=\"#prepare-app\">Prepare Your Own Application for Deployment</a></li>
<li>
<a href=\"#parent\">AKA, the Nest</a><ul>
<li><a href=\"#child\">The Nestee</a></li>
<li><a href=\"#bro\">The Nestee's Brother</a></li>
</ul>
</li>
<li><a href=\"#uncle\">Not nested</a></li>
</ul></div>
HTML
        end

        it 'nests links' do
          expect(quick_links).to eq(expected_output.strip)
        end
      end

      context 'when a header contains no anchors' do
        let(:sample_markdown) do
<<MARKDOWN
## <a id='my-id'></a> With an anchor
## <a></a> Without an id
## Without an anchor
MARKDOWN
        end

        let(:expected_output) do
<<HTML
<div class=\"quick-links\"><ul><li><a href=\"#my-id\">With an anchor</a></li></ul></div>
HTML
        end

        it 'is not linked to' do
          expect(quick_links).to eq(expected_output.strip)
        end
      end

      context 'when there are no headers' do
        let(:sample_markdown) do
<<MARKDOWN
## <a></a> Without an id
## Without an anchor
MARKDOWN
        end

        let(:expected_output) { '' }

        it 'is an empty string' do
          expect(quick_links).to eq(expected_output.strip)
        end
      end
    end
  end
end