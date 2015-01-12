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

        attr_reader :config, :template, :partial_options

        def initialize(config)
          @config = config
        end

        def partial(template, options={}, &block)
          @template = template
          @partial_options = options
        end
      end
    end

    before do
      allow(BookbinderLogger).to receive(:new).and_return(logger)
    end

    def run_middleman(template_variables: {}, subnav_templates: {}, archive_menu: {})
      original_mm_root = ENV['MM_ROOT']

      Middleman::Cli::Build.instance_variable_set(:@_shared_instance, nil)
      ENV['MM_ROOT'] = tmpdir.to_s
      Dir.chdir(tmpdir) do
        build_command = Middleman::Cli::Build.new [], {:quiet => false}, {}
        Middleman::Cli::Build.shared_instance(false).config[:template_variables] = template_variables
        Middleman::Cli::Build.shared_instance(false).config[:subnav_templates] = subnav_templates
        Middleman::Cli::Build.shared_instance(false).config[:archive_menu] = archive_menu
        build_command.invoke :build, [], {:verbose => false}
      end

      ENV['MM_ROOT'] = original_mm_root
    end

    describe 'injecting customized drop down menu based on archive_menu key inside config' do
      let(:source_dir) { tmp_subdir 'source' }
      let(:source_file_content) { '<%= yield_for_archive_drop_down_menu %>' }
      let(:source_file_under_test) { 'index.md.erb' }
      let(:source_file_title) { 'Dogs' }
      let(:output) { File.read File.join(tmpdir, 'build', 'index.html') }
      let(:partial_content) do
        '<div class="header-dropdown"><a class="header-dropdown-link"><%= menu_title %></a></div><div class="header-dropdown-content"><ul><% for link in dropdown_links %><li><a href="<%= link.values.first %>"><%= link.keys.first %></a></li><% end %></ul></div>'
      end
      let(:first_version) { 'v3.0.0.0' }
      let(:past_versions) { { 'v2.0.0.0' => 'archives/pcf-docs-1.2.pdf' } }
      let(:archive_menu) do
        [
            first_version,
            past_versions
        ]
      end

      before do
        FileUtils.cp_r 'master_middleman/.', tmpdir
        FileUtils.mkdir_p source_dir
        squelch_middleman_output
        write_markdown_source_file source_file_under_test, source_file_title, source_file_content
      end

      context 'when the archive template does exist' do
        before do
          write_archive_menu_content "archive_menus/_default.erb", partial_content
        end

        context 'when the archive menu tag contains versions' do
          let(:expected_past_versions) { { 'v2.0.0.0' => '/archives/pcf-docs-1.2.pdf' } }

          it 'renders a default archive_menu template with the archive versions' do
            run_middleman(archive_menu: archive_menu)
            doc = Nokogiri::HTML(output)
            expect(doc.css('div .header-dropdown-link').text).to eq(first_version)
            expect(doc.css('.header-dropdown-content').text).to eq(past_versions.keys.first)
            expect(doc.css('.header-dropdown-content ul li a').first['href']).to eq("#{expected_past_versions.values.first}")
          end
        end

        context 'when the optional archive menu key is not present' do
          it 'should run middleman without including the key' do
            expect do
              original_mm_root = ENV['MM_ROOT']

              Middleman::Cli::Build.instance_variable_set(:@_shared_instance, nil)
              ENV['MM_ROOT'] = tmpdir.to_s
              Dir.chdir(tmpdir) do
                build_command = Middleman::Cli::Build.new [], {:quiet => false}, {}
                build_command.invoke :build, [], {:verbose => false}
              end

              ENV['MM_ROOT'] = original_mm_root

            end.to_not raise_error
          end
        end

        context 'when only one version is specified' do
          let(:archive_menu) do
            [
                first_version
            ]
          end

          it 'renders an archive_menu template with the archive version' do
            run_middleman(archive_menu: archive_menu)
            doc = Nokogiri::HTML(output)
            expect(doc.css('div .header-dropdown-link').text).to eq(first_version)
          end
        end
      end
    end

    describe '#yield_for_code_snippet' do
      let(:config) { {} }
      let(:yielded_snippet) do
        klass.new(config).yield_for_code_snippet(from: repo, at: excerpt_mark)
      end
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
        let(:config) { {local_repo_dir: nil, git_accessor: SpecGitAccessor} }

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
      include_context 'tmp_dirs'

      let(:source_dir) { tmp_subdir 'source' }
      let(:source_file_content) { '<%= yield_for_subnav %>' }
      let(:source_file_under_test) { 'index.md.erb' }
      let(:source_file_title) { 'Dogs' }
      let(:output) { File.read File.join(tmpdir, 'build', 'index.html') }
      let(:breadcrumb_title) { nil }

      before do
        FileUtils.cp_r 'master_middleman/.', tmpdir
        FileUtils.mkdir_p source_dir
        squelch_middleman_output
        write_markdown_source_file source_file_under_test, source_file_title, source_file_content, breadcrumb_title, index_subnav
        write_subnav_content "subnavs/default.erb", ''
      end

      context 'when invoked in the top-level index file' do
        context 'and a subnav specified in the index markdown' do
          let(:index_subnav) { 'index-subnav' }
          let(:subnav_code) do
            '<div id="sub-nav" class="js-sidenav" collapsible nav-container" role="navigation" data-behavior="Collapsible">
  <a class="sidenav-title"" data-behavior="SubMenuMobile">Index Subnav</a>
</div>'
          end

          it 'populates with the specified index subnav' do
            write_subnav_content "subnavs/#{index_subnav}.erb", subnav_code
            run_middleman
            doc = Nokogiri::HTML(output)
            expect(doc.css('div')[0].first[1]).to eq('sub-nav')
            expect(doc.css('a').text).to eq('Index Subnav')
          end
        end

        context 'and a subnav is not specified in the index markdown' do
          let(:index_subnav) { nil }
          let(:subnav_code) { '' }
          it 'yields the empty "default" subnav' do
            run_middleman
            expect(output).to be_empty
          end
        end
      end

      context 'when the page is a section page' do
        let(:section_directory) { 'some-dir' }
        let(:source_file_under_test) { "#{section_directory}/some-section.erb" }
        let(:output) { File.read File.join(tmpdir, 'build', section_directory, 'some-section.html' ) }
        let(:subnav) { 'section-subnav' }
        let(:index_subnav) { nil }
        let(:subnav_code) do
          '<div id="sub-nav" class="js-sidenav" collapsible nav-container" role="navigation" data-behavior="Collapsible">
  <a class="sidenav-title"" data-behavior="SubMenuMobile">Section Subnav</a>
</div>'
        end

        before do
          write_markdown_source_file source_file_under_test, source_file_title, source_file_content
        end

        context 'and a subnav is specified' do
          it 'inserts the subnav specified in the config' do
            write_subnav_content "subnavs/#{subnav}.erb", subnav_code
            run_middleman(subnav_templates: { section_directory => subnav })
            doc = Nokogiri::HTML(output)

            expect(doc.css('div')[0].first[1]).to eq('sub-nav')
            expect(doc.css('a').text).to eq('Section Subnav')
          end
        end

        context 'and a subnav is not specified' do
          let(:subnav){ nil }
          it 'inserts the default subnav' do
            run_middleman(subnav_templates: { section_directory => subnav })
            expect(output).to be_empty
          end
        end
      end
    end

    describe '#modified_date' do
      subject(:an_instance) { klass.new(config) }

      let(:moon_section) { Section.new(logger, repo, 'my_subnav_template', 'path/to/moon') }
      let(:fraggle_section) { Section.new(logger, GitHubRepository.new(full_name: '', directory: 'fraggles/rock'), nil, 'path/to/fraggles') }
      let(:sections) { [moon_section, fraggle_section] }
      let(:book){ Book.new(full_name: 'full/path') }
      let(:config) { {sections: sections, book: book} }
      let(:file_path) { "moon/history.html" }
      let(:source_file_path) { "/my/full/path/moon/history.html.md" }
      let(:file_modification_date) { '19 Jan 3028' }

      let(:repo_name) { '' }
      let(:repo) { GitHubRepository.new(logger: logger, full_name: repo_name, directory: 'moon') }
      let(:destination_dir) { tmp_subdir('destination') }
      let(:git_base_object) { double Git::Base }
      let(:git_history) { double Git::Log }
      let(:git_history_most_recent_entry) { double Git::Log }
      let(:most_recent_commit) { double Git::Object::Commit }

      let(:current_page_object) { double Middleman::Sitemap::Resource }

      let(:some_time) { Time.new(3028, 1, 19) }

      before do
        allow(Git).to receive(:clone).and_return(git_base_object)
        allow(git_base_object).to receive(:checkout)
        repo.copy_from_remote(destination_dir)

        allow(git_base_object).to receive(:log).with(1).and_return(git_history)

        allow(git_history).to receive(:object).with('history.html.md').and_return(git_history_most_recent_entry)
        allow(git_history_most_recent_entry).to receive(:first).and_return most_recent_commit
        allow(most_recent_commit).to receive(:date).and_return some_time

        allow(an_instance).to receive(:current_path).and_return file_path
        allow(an_instance).to receive(:current_page).and_return current_page_object
        allow(current_page_object).to receive(:source_file).and_return source_file_path
      end

      it 'gets the date for each file from the section' do
        expect(an_instance.modified_date('%e %b %Y')).to eq file_modification_date
      end

      it 'gets the date even if the file path is more specific than the directory of the section' do
        file_path = "moon/colonization/history.html"
        allow(an_instance).to receive(:current_path).and_return file_path
        allow(git_history).to receive(:object).with('colonization/history.html.md').and_return(git_history_most_recent_entry)
        expect(an_instance.modified_date('%e %b %Y')).to eq file_modification_date
      end

      context 'the sections are incorrectly passed to middleman' do
        let(:config) { { sections: nil, book: nil } }
        it 'raises an informative error' do
          allow(an_instance).to receive(:current_path).and_return('some-path')
          expect{ an_instance.modified_date }.to raise_error(/Book or Selections are incorrectly specified/)
        end
      end

      context 'when the current path belongs to the book' do
        let(:destination_dir) { tmp_subdir('destination') }
        let(:git_base_object) { double Git::Base }
        let(:git_history) { double Git::Log }
        let(:git_history_most_recent_entry) { double Git::Log }
        let(:most_recent_commit) { double Git::Object::Commit }

        let(:book) { Book.new(full_name: 'stars/my-galaxy-book') }
        let(:config) { { book: book, sections: [] } }
        let(:file_path) { 'index.html' }
        let(:current_page_object) { double Middleman::Sitemap::Resource }
        let(:source_file_path) { '/my/long/path/my-galaxy-book/output/master_middleman/source/index.html.md' }

        let(:file_modification_date) { '19 Jan 3028' }
        let(:some_time) { Time.new(3028, 1, 19) }

        before do
          allow(Git).to receive(:open).with('/my/long/path/my-galaxy-book/').and_return(git_base_object)
          allow(git_base_object).to receive(:log).with(1).and_return(git_history)
          allow(git_history).to receive(:object).with('master_middleman/source/index.html.md').and_return(git_history_most_recent_entry)
          allow(git_history_most_recent_entry).to receive(:first).and_return most_recent_commit
          allow(most_recent_commit).to receive(:date).and_return some_time

          allow(an_instance).to receive(:current_path).and_return file_path
          allow(an_instance).to receive(:current_page).and_return current_page_object
          allow(current_page_object).to receive(:source_file).and_return source_file_path
        end

        it 'gets the date for each file in the book' do
          expect(an_instance.modified_date).to eq some_time
        end

        it 'gets the formatted date for each file in the book' do
          expect(an_instance.modified_date('%e %b %Y')).to eq file_modification_date
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
          run_middleman(template_variables: { 'var_name' => 'A Variable Value' } )
          expect(output).to include('A Variable Value')
        end
      end
    end

    describe '#quick_links' do
      subject(:an_instance) { klass.new({}) }

      let(:quick_links) { an_instance.quick_links }
      let(:current_page) { double(:current_page, source_file: nil) }

      before { allow(an_instance).to receive(:current_page).and_return(current_page) }

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

      context 'when the headers contain erb' do
        let(:vars) { OpenStruct.new(erb_text: 'ERB Anchor') }
        let(:sample_markdown) do
          <<MARKDOWN
## <a id='my-id-one'></a> Normal Anchor
## <a id='my-id-two'></a><%= vars.erb_text %>
MARKDOWN
        end

        let(:expected_output) do
          <<HTML
<div class=\"quick-links\"><ul>\n<li><a href=\"#my-id-one\">Normal Anchor</a></li>
<li><a href=\"#my-id-two\">ERB Anchor</a></li>\n</ul></div>
HTML
        end

        it 'interprets the erb' do
          vars = OpenStruct.new( erb_text: 'ERB Anchor')
          renderer = QuicklinksRenderer.new(vars)
          rendered_material = Redcarpet::Markdown.new(renderer).render(sample_markdown)

          allow(QuicklinksRenderer).to receive(:new).and_return(renderer)
          allow_any_instance_of(Redcarpet::Markdown).to receive(:render).and_return(rendered_material)

          expect(quick_links).to eq(expected_output.strip)
        end
      end
    end
  end
end
