require 'i18n'
require 'middleman'
require 'middleman-core/cli'
require 'middleman-core/profiling'
require 'ostruct'
require 'redcarpet'
require 'yaml'
require_relative '../../../lib/bookbinder/middleman_runner'
require_relative '../../helpers/middleman'
require_relative '../../helpers/redirection'
require_relative '../../helpers/tmp_dirs'
require_relative '../../helpers/use_fixture_repo'
require_relative '../../helpers/git_repo'

require './master_middleman/bookbinder_helpers'

module Bookbinder
  describe Navigation::HelperMethods do
    include Bookbinder::SpecHelperMethods
    include Bookbinder::GitRepo
    include_context 'tmp_dirs'

    let(:klass) do
      Class.new do
        include Navigation::HelperMethods

        attr_reader :config, :template, :partial_options

        def initialize(config = {})
          @config = config
        end

        def partial(template, options={}, &block)
          @template = template
          @partial_options = options
        end
      end
    end

    def run_middleman(template_variables: {}, subnav_templates: {}, archive_menu: {}, feedback_enabled: false, repo_link_enabled: false, repo_links: {})
      original_mm_root = ENV['MM_ROOT']

      Middleman::Cli::Build.instance_variable_set(:@_shared_instance, nil)
      ENV['MM_ROOT'] = tmpdir.to_s
      Dir.chdir(tmpdir) do
        build_command = Middleman::Cli::Build.new [], {:quiet => false}, {}
        File.write('bookbinder_config.yml', YAML.dump(template_variables: template_variables,
                                                      subnav_templates: subnav_templates,
                                                      archive_menu: archive_menu,
                                                      feedback_enabled: feedback_enabled,
                                                      repo_link_enabled: repo_link_enabled,
                                                      repo_links: repo_links))
        build_command.invoke :build, [], {:verbose => true}
      end

      ENV['MM_ROOT'] = original_mm_root
    end

    describe 'injecting customized drop down menu based on archive_menu key inside config' do
      let(:archive_menu) do
        { '.' => [ 'v3.0.0.0', { 'v2.0.0.0' => 'archives/pcf-docs-1.2.pdf' } ] }
      end
      let(:helper) { klass.new(archive_menu: archive_menu) }
      let(:current_page) { double(:current_page, path: 'index.md.erb' ) }

      before do
        allow(helper).to receive(:current_page) { current_page }
      end

      context 'when the archive menu tag contains versions' do
        it 'renders a default archive_menu template with the archive versions' do
          helper.yield_for_archive_drop_down_menu

          expect(helper.template).to eq('archive_menus/default')
          expect(helper.partial_options).to eq({
            :locals => {
              :menu_title => 'v3.0.0.0',
              :dropdown_links => [
                {'v2.0.0.0' => '/archives/pcf-docs-1.2.pdf'}
              ]
            }
          })
        end
      end

      context 'when the optional archive menu key is not present' do
        let(:helper) { klass.new }

        it 'should not render the archive_menu partial' do
          helper.yield_for_archive_drop_down_menu

          expect(helper.template).to be_nil
          expect(helper.partial_options).to be_nil
        end
      end
    end

    describe '#mermaid_diagram' do
      it 'wraps given content in div.mermaid' do
        FileUtils.cp_r 'master_middleman/.', tmpdir

        init_repo(at_dir: tmp_subdir('source/sections/section-repo'),
                  contents: "<% mermaid_diagram do%>
                             filler text
                             <% end %>",
                  file: 'index.html.md.erb')

        squelch_middleman_output
        run_middleman

        output = tmpdir.join('build', 'sections', 'section-repo', 'index.html').read
        doc = Nokogiri::HTML(output)

        expect(doc.css('div.mermaid').empty?).to eq(false)
      end

      it 'escapes dashes' do
        FileUtils.cp_r 'master_middleman/.', tmpdir

        init_repo(at_dir: tmp_subdir('source/sections/section-repo'),
          contents: "<% mermaid_diagram do%>some--->thing-good<% end %>",
          file: 'index.html.md.erb')

        squelch_middleman_output
        run_middleman

        output = tmpdir.join('build', 'sections', 'section-repo', 'index.html').read
        doc = Nokogiri::HTML(output)

        expect(doc.css('div.mermaid').first.inner_html).to eq('some---&gt;thing-good')
      end
    end

    describe '#modified_date' do
      let(:helper) { klass.new({}) }
      let(:git_accessor) { double(:git_accessor) }
      let(:current_page) { double(:current_page, data: page_data) }
      let(:page_data) { double(:page_data) }

      before do
        allow(Ingest::GitAccessor).to receive(:new) { git_accessor }
        allow(helper).to receive(:current_page) { current_page }
      end

      it 'returns the last modified date of the file' do
        date = Time.new(1995, 1, 3, 2, 2, 2, "+02:00")
        allow(page_data).to receive(:dita) { false }
        allow(current_page).to receive(:source_file) { 'index.html.md.erb' }

        expect(git_accessor).to receive(:author_date).with('index.html.md.erb') { date }
        expect(helper.modified_date).to eq(
          "Page last updated: <span data-behavior=\"DisplayModifiedDate\" data-modified-date=\"#{date.utc}\"></span>"
        )
      end

      it 'finds the appropriate modification date for dita files' do
          date = Time.new(1995, 1, 3)
          allow(page_data).to receive(:dita) { true }
          allow(current_page).to receive(:source_file) { 'foo/source/index.html.md.erb' }

          expect(git_accessor).to receive(:author_date).with('foo/output/preprocessing/sections/index.html.md.erb', dita: true) { date }

          expect(helper.modified_date).to eq(
            "Page last updated: <span data-behavior=\"DisplayModifiedDate\" data-modified-date=\"#{date.utc}\"></span>"
          )
      end

      it 'returns nothing for a file with no last modified date in git' do
        allow(page_data).to receive(:dita) { false }
        allow(current_page).to receive(:source_file) { 'index.html.md.erb' }

        expect(git_accessor).to receive(:author_date).with('index.html.md.erb') { nil }
        expect(helper.modified_date).to be_nil
      end

      it 'returns the user-provided date for a file with no last modified date in git' do
        default_date = Time.new(1999, 12, 31)

        allow(page_data).to receive(:dita) { false }
        allow(current_page).to receive(:source_file) { 'index.html.md.erb' }

        expect(git_accessor).to receive(:author_date).with('index.html.md.erb') { nil }
        expect(helper.modified_date(default_date: "December 31, 1999")).to eq(
          "Page last updated: <span data-behavior=\"DisplayModifiedDate\" data-modified-date=\"#{default_date.utc}\"></span>"
        )
      end
    end

    describe '#yield_for_feedback' do
      before(:each) do
        FileUtils.cp_r 'master_middleman/.', tmpdir
        FileUtils.mkdir_p(File.join(tmpdir, 'source','layouts'))
        File.open(File.join(tmpdir, 'source', 'index.html.erb'), 'w') do |f|
          f.write('<%= yield_for_feedback %>')
        end
        File.open(File.join(tmpdir, 'source', 'layouts', '_feedback.erb'), 'w') do |f|
          f.write('Hella feedback')
        end
      end

      context 'when feedback is enabled' do
        it 'renders feedback partial' do
          squelch_middleman_output
          run_middleman(feedback_enabled: true)

          output = File.read(tmpdir.join('build', 'index.html'))

          expect(output).to include('Hella feedback')
        end

        it 'does not render feedback partial on page marked for exclusion' do
          File.open(File.join(tmpdir, 'source', 'index_two.html.erb'), 'w') do |f|
            f.write('<% exclude_feedback %>')
          end

          File.open(File.join(tmpdir, 'source', 'index.html.erb'), 'w') do |f|
            f.write('Some dummy text')
          end

          File.open(File.join(tmpdir, 'source', 'layouts', 'layout.erb'), 'w') do |f|
            f.write('<%= yield %>')
            f.write('<%= yield_for_feedback %>')
          end

          squelch_middleman_output
          run_middleman(feedback_enabled: true)

          output = File.read(tmpdir.join('build', 'index.html'))
          expect(output).to include('Hella feedback')

          output_two = File.read(tmpdir.join('build', 'index_two.html'))
          expect(output_two).to_not include('Hella feedback')
        end
      end

      context 'when feedback is not enabled' do
        it 'does not render feedback partial' do
          squelch_middleman_output
          run_middleman(feedback_enabled: false)

          output = File.read(tmpdir.join('build', 'index.html'))

          expect(output).to_not include('Hella feedback')
        end
      end
    end

    describe '#render_repo_link' do
      before(:each) do
        FileUtils.cp_r 'master_middleman/.', tmpdir
        FileUtils.mkdir_p(File.join(tmpdir, 'source','layouts'))
        FileUtils.mkdir_p(File.join(tmpdir, 'source', 'desired', 'dir'))
      end
      context 'when repo link is enabled' do
        context 'when the page url directories exactly match the desired dir' do
          it 'renders the repo link using the values from bookbinder config' do
            File.open(File.join(tmpdir, 'source', 'desired', 'dir', 'index.html.erb'), 'w') do |f|
              f.write("<%= render_repo_link(include_environments: ['ocean-trench', 'martian-wasteland']) %>")
            end

            squelch_middleman_output
            run_middleman(
              repo_link_enabled: true,
              repo_links: {
                'desired/dir' => {
                  'repo' => 'the-best-repo-evah',
                  'ref' => 'awesome-ref'
                }
              }
            )

            output = File.read(tmpdir.join('build', 'desired', 'dir', 'index.html'))

            expected_url = "<a id='repo-link' data-whitelist='ocean-trench martian-wasteland' style='display: none;' href='http://github.com/the-best-repo-evah/tree/awesome-ref/index.html.md.erb'>View the source for this page in GitHub</a>"

            expect(output).to include(expected_url)
          end
        end

        context 'when the page url directories are not an exact match for the desired dir' do
          context 'when at_path is specified and the page has no nested directory' do
            it 'renders the repo link using the current page url and values from bookbinder config' do
              File.open(File.join(tmpdir, 'source', 'desired', 'dir', 'index.html.erb'), 'w') do |f|
                f.write('<%= render_repo_link %>')
              end

              squelch_middleman_output
              run_middleman(repo_link_enabled: true, repo_links: {
                  'desired/dir' => {
                    'repo' => 'the-best-repo-evah',
                    'ref' => 'master',
                    'at_path' => 'some/path'
                  }
                }
              )

              output = File.read(tmpdir.join('build', 'desired', 'dir', 'index.html'))

              expect(output).to include("<a id='repo-link' data-whitelist='' style='display: none;' href='http://github.com/the-best-repo-evah/tree/master/some/path/index.html.md.erb'>View the source for this page in GitHub</a>")
            end
          end

          context 'when at_path is not specified and the page has a nested directory' do
            it 'renders the repo link using the current page url and values from bookbinder config' do
              FileUtils.mkdir_p(File.join(tmpdir, 'source', 'desired', 'dir', 'nested'))
              File.open(File.join(tmpdir, 'source', 'desired', 'dir', 'nested', 'index.html.erb'), 'w') do |f|
                f.write('<%= render_repo_link %>')
              end

              squelch_middleman_output
              run_middleman(repo_link_enabled: true, repo_links: {
                  'desired/dir' => {
                    'repo' => 'the-best-repo-evah',
                    'ref' => 'master'
                  }
                }
              )

              output = File.read(tmpdir.join('build', 'desired', 'dir', 'nested', 'index.html'))

              expect(output).to include("<a id='repo-link' data-whitelist='' style='display: none;' href='http://github.com/the-best-repo-evah/tree/master/nested/index.html.md.erb'>View the source for this page in GitHub</a>")
            end
          end

          context 'when at_path is specified and the page has a nested directory' do
            it 'renders the repo link using the current page url and values from bookbinder config' do
              FileUtils.mkdir_p(File.join(tmpdir, 'source', 'desired', 'dir', 'nested'))
              File.open(File.join(tmpdir, 'source', 'desired', 'dir', 'nested', 'index.html.erb'), 'w') do |f|
                f.write('<%= render_repo_link %>')
              end

              squelch_middleman_output
              run_middleman(repo_link_enabled: true, repo_links: {
                  'desired/dir' => {
                    'repo' => 'the-best-repo-evah',
                    'ref' => 'master',
                    'at_path' => 'some/path'
                  }
                }
              )

              output = File.read(tmpdir.join('build', 'desired', 'dir', 'nested', 'index.html'))

              expect(output).to include("<a id='repo-link' data-whitelist='' style='display: none;' href='http://github.com/the-best-repo-evah/tree/master/nested/some/path/index.html.md.erb'>View the source for this page in GitHub</a>")
            end
          end

          it 'matches the desired directory when there is another directory that is a substring of the correct match' do
            dita_frontmatter = <<-EOT
---
dita: true
---
            EOT

            FileUtils.mkdir_p(File.join(tmpdir, 'source', 'desired', 'dir', 'nested'))
            File.open(File.join(tmpdir, 'source', 'desired', 'dir', 'nested', 'index.html.erb'), 'w') do |f|
              f.write(dita_frontmatter)
              f.write('<%= render_repo_link %>')
            end

            init_repo(at_dir: tmp_subdir('output/preprocessing/sections/desired/dir/nested'),
              contents: '<%= modified_date %>',
              file: 'index.xml')

            squelch_middleman_output
            run_middleman(repo_link_enabled: true, repo_links: {
                'desired' => {
                  'repo' => 'the-best-repo-evah-in-the-historeh-of-the-universe',
                  'ref' => 'bogus-branch',
                  'at_path' => 'some/bogus/path'
                },
                'desired/dir' => {
                  'repo' => 'the-best-repo-evah',
                  'ref' => 'master',
                  'at_path' => 'some/path'
                }
              }
            )

            output = File.read(tmpdir.join('build', 'desired', 'dir', 'nested', 'index.html'))
            expect(output).to include("<a id='repo-link' data-whitelist='' style='display: none;' href='http://github.com/the-best-repo-evah/tree/master/nested/some/path/index.xml'>View the source for this page in GitHub</a>")
          end
        end

        it 'links to the parent directory if full source file for current page does not exist in version control' do
          dita_frontmatter = <<-EOT
---
dita: true
---
          EOT

          File.open(File.join(tmpdir, 'source', 'desired', 'dir', 'index.html.erb'), 'w') do |f|
            f.write(dita_frontmatter)
            f.write("<%= render_repo_link %>")
          end

          init_repo(at_dir: tmp_subdir('output/preprocessing/sections/desired/dir'),
                    contents: '<%= render_repo_link %>',
                    file: 'not-the-source.xml')

          squelch_middleman_output
          run_middleman(
            repo_link_enabled: true,
            repo_links: {
              'desired/dir' => {
                'repo' => 'the-best-repo-evah',
                'ref' => 'awesome-ref'
              }
            }
          )

          output = File.read(tmpdir.join('build', 'desired', 'dir', 'index.html'))

          expected_url = "<a id='repo-link' data-whitelist='' style='display: none;' href='http://github.com/the-best-repo-evah/tree/awesome-ref'>View the source for this page in GitHub</a>"

          expect(output).to include(expected_url)
        end

        it 'does not render repo link on page marked for exclusion' do
          FileUtils.mkdir_p(File.join(tmpdir, 'source', 'dir-one'))
          FileUtils.mkdir_p(File.join(tmpdir, 'source', 'dir-two'))
          File.open(File.join(tmpdir, 'source', 'dir-one', 'index_one.html.erb'), 'w') do |f|
            f.write('<% exclude_repo_link %>')
          end

          File.open(File.join(tmpdir, 'source', 'dir-two', 'index_two.html.erb'), 'w') do |f|
            f.write('Some dummy text')
          end

          File.open(File.join(tmpdir, 'source', 'layouts', 'layout.erb'), 'w') do |f|
            f.write('<%= yield %>')
            f.write('<%= render_repo_link %>')
          end

          squelch_middleman_output
          run_middleman(
            repo_link_enabled: true,
            repo_links: {
              'dir-one' => {'repo' => 'repo-one', 'ref' => 'awesome-ref'},
              'dir-two' => {'repo' => 'repo-two', 'ref' => 'master'}
            }
          )

          output_one = File.read(tmpdir.join('build', 'dir-one', 'index_one.html'))
          output_two = File.read(tmpdir.join('build', 'dir-two', 'index_two.html'))

          expect(output_one).to_not include("<a id='repo-link' data-whitelist='' style='display: none;' href='http://github.com/repo-one/tree/awesome-ref/dir-one/index_one.html.md.erb'>View the source for this page in GitHub</a>")
          expect(output_two).to include("<a id='repo-link' data-whitelist='' style='display: none;' href='http://github.com/repo-two/tree/master/index_two.html.md.erb'>View the source for this page in GitHub</a>")
        end

        it 'does not render a link when binding locally' do
          File.open(File.join(tmpdir, 'source', 'desired', 'dir', 'index.html.erb'), 'w') do |f|
            f.write('<%= render_repo_link %>')
          end

          squelch_middleman_output
          run_middleman(
            repo_link_enabled: true,
            repo_links: {
              'dir' => {'repo' => 'repo-one'}
            }
          )

          output = File.read(tmpdir.join('build', 'desired', 'dir', 'index.html'))

          expect(output).to_not include("View the source for this page in GitHub")
        end
      end

      context 'when repo link is not enabled' do
        it 'does not render the repo link' do
          File.open(File.join(tmpdir, 'source', 'desired', 'dir', 'index.html.erb'), 'w') do |f|
            f.write('<%= render_repo_link %>')
          end

          squelch_middleman_output
          run_middleman(
            repo_link_enabled: false,
          )

          output = File.read(tmpdir.join('build', 'desired', 'dir', 'index.html'))

          expect(output).to_not include("View the source for this page in GitHub")
        end
      end
    end

    describe '#yield_for_code_snippet' do
      let(:repo) { 'fantastic/code-example-repo' }
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
      let(:excerpt_mark) { 'complicated_function' }
      let(:config) { {workspace: File.absolute_path('../my-special-workspace'),
                      local_repo_dir: File.absolute_path('../../../fixtures/repositories', __FILE__)} }

      use_fixture_repo

      let(:yielded_snippet) do
        klass.new(config).yield_for_code_snippet(from: repo, at: excerpt_mark)
      end

      include Redirection

      it 'returns markdown from the cloned repo' do
        swallow_stdout do
          expect(yielded_snippet).to eq(markdown_snippet.chomp)
        end
      end
    end

    describe '#yield_for_subnav' do
      let(:helper) { klass.new(subnav_templates: { 'foo' => 'bar.erb', 'baz' => 'quux.erb', '1' => '2.erb' }) }

      before do
        allow(helper).to receive(:current_path) { 'foo/things.html' }
      end

      it 'renders the first subnav for search' do
        allow(helper).to receive(:current_path) { 'search.html' }
        helper.yield_for_subnav

        expect(helper.template).to eq('subnavs/bar.erb')
      end

      it 'renders a matching subnav from the body classes' do
        allow(helper).to receive(:page_classes) { 'flerb baz dingo' }
        helper.yield_for_subnav

        expect(helper.template).to eq('subnavs/quux.erb')
      end

      it 'allows subnav keys to start with a number' do
        allow(helper).to receive(:page_classes).with('foo/things.html', {numeric_prefix: 'NUMERIC_CLASS_PREFIX'}) { 'blah NUMERIC_CLASS_PREFIX1 blerg' }
        helper.yield_for_subnav

        expect(helper.template).to eq('subnavs/2.erb')
      end

      it 'corrects for .s in the directory for classnames' do
        allow(helper).to receive(:current_path) {'many.folders/things.html'}
        allow(helper).to receive(:page_classes) { 'blah 1 blerg' }
        helper.yield_for_subnav

        expect(helper).to have_received(:page_classes).with('many_folders/things.html', instance_of(Hash))
      end

      it 'finds the most specifically matching subnav' do
        allow(helper).to receive(:page_classes) { 'bleh blah baz foo blah' }
        helper.yield_for_subnav

        expect(helper.template).to eq('subnavs/bar.erb')
      end

      it 'ignores a subnav just for the page' do
        allow(helper).to receive(:page_classes) { 'baz blah foo' }
        helper.yield_for_subnav

        expect(helper.template).to eq('subnavs/quux.erb')
      end

      it 'uses the default subnav if no key matches' do
        allow(helper).to receive(:page_classes) { 'bleh blah blubb' }
        helper.yield_for_subnav

        expect(helper.template).to eq('subnavs/default')
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
          doc = Nokogiri::HTML(output)
          expect(doc.css('ul.breadcrumbs').length).to eq(0)
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
          expect(doc.css('ul.breadcrumbs li').length).to eq(2)
        end

        it 'creates entries for each level of the hierarchy' do
          run_middleman
          doc = Nokogiri::HTML(output)
          expect(doc.css('ul.breadcrumbs li')[0].text).to eq('Dogs')
          expect(doc.css('ul.breadcrumbs li')[1].text).to eq('Big Dogs')
        end

        it 'gives the last entry an "active" class' do
          run_middleman
          doc = Nokogiri::HTML(output)
          expect(doc.css('ul.breadcrumbs li')[0]['class']).to be_nil
          expect(doc.css('ul.breadcrumbs li')[1]['class']).to eq('active')
        end

        context 'when the parent also has a breadcrumb title' do
          let(:breadcrumb_title) { 'Fancy Schmancy New Title' }
          it 'uses the breadcrumb title instead of the title' do
            run_middleman
            doc = Nokogiri::HTML(output)
            expect(doc.css('ul.breadcrumbs li')[0].text).to eq('Dogs')
            expect(doc.css('ul.breadcrumbs li')[1].text).to eq('Fancy Schmancy New Title')
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
          expect(doc.css('ul.breadcrumbs li').length).to eq(0)
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

    describe '#owners' do
      subject(:owners) { klass.owners }
      let(:klass) { OpenStruct.new(sitemap: sitemap).tap {|k| k.extend(Navigation::HelperMethods) } }
      let(:sitemap) { instance_double('Middleman::Sitemap::Store', resources: resources) }
      let(:resources) {
        [
          ['some/non/html/path', nil],
          ['no/owner/for/this/path.html', nil],
          ['one/owner.html', 'Alice'],
          ['multiple/owners.html', %w[ Bob Charlie ]],
        ].map {|path,owner| instance_double('Middleman::Sitemap::Resource', path: path, data: {'owner' => owner})}
      }

      before do
        allow(klass).to receive(:sitemap).and_return(sitemap)
      end

      it 'should not include non-html files' do
        expect(owners).not_to include('some/non/html/path')
      end

      it 'should include files without owners' do
        expect(owners).to include('no/owner/for/this/path.html' => [])
      end

      it 'should return an array of owners even when there is only one' do
        expect(owners).to include('one/owner.html' => ['Alice'])
      end

      it 'should include files with multiple owners' do
        expect(owners).to include('multiple/owners.html' => %w[ Bob Charlie ])
      end
    end
  end
end
