require 'webmock/rspec'

require_relative '../../helpers/tmp_dirs'
require_relative '../../helpers/spec_git_accessor'
require_relative '../../helpers/nil_logger'
require_relative '../../helpers/middleman'
require_relative '../../fixtures/repo_fixture'
require_relative '../../../lib/bookbinder/publisher'
require_relative '../../../lib/bookbinder/spider'
require_relative '../../../lib/bookbinder/book'
require_relative '../../../lib/bookbinder/middleman_runner'

module Bookbinder
  describe Publisher do
    describe '#publish' do
      include_context 'tmp_dirs'

      let(:logger) { NilLogger.new }
      let(:spider) { Spider.new(logger, app_dir: final_app_dir) }
      let(:static_site_generator) { MiddlemanRunner.new logger }
      let(:publisher) { Publisher.new(logger, spider, static_site_generator) }
      let(:output_dir) { tmp_subdir 'output' }
      let(:final_app_dir) { tmp_subdir 'final_app' }
      let(:non_broken_master_middleman_dir) { generate_middleman_with 'non_broken_index.html' }
      let(:dogs_master_middleman_dir) { generate_middleman_with 'dogs_index.html' }
      let(:archive_menu) { {} }
      let(:git_client) { GitClient.new(logger) }
      let(:working_links) { [] }

      context 'integration' do
        include SpecHelperMethods

        before do
          squelch_middleman_output
          allow(BookbinderLogger).to receive(:new).and_return(NilLogger.new)
          allow(ProgressBar).to receive(:create).and_return(double(increment: nil))
          WebMock.disable_net_connect!(:allow_localhost => true)
        end

        after { WebMock.disable_net_connect! }

        let(:local_repo_dir) { RepoFixture.repos_dir }
        let(:book) { 'some-repo/some-book' }

        it 'creates a directory per repo with the generated html from middleman' do
          some_repo = 'my-docs-org/my-docs-repo'
          some_other_repo = 'my-other-docs-org/my-other-docs-repo'
          some_sha = 'some-sha'
          some_other_sha = 'some-other-sha'

          expect(SpecGitAccessor).to receive(:clone).with("git@github.com:#{some_repo}",
                                              "pretty_path",
                                              anything).and_call_original

          expect(SpecGitAccessor).to receive(:clone).with("git@github.com:#{some_other_repo}",
                                             File.basename(some_other_repo),
                                             anything).and_call_original
          sections = [
              {'repository' => {'name' => some_repo, 'ref' => some_sha}, 'directory' => 'pretty_path'},
              {'repository' => {'name' => some_other_repo, 'ref' => some_other_sha}}
          ]

          output_paths = {
              output_dir: output_dir,
              master_middleman_dir: non_broken_master_middleman_dir,
              final_app_dir: final_app_dir
          }

          publish_config = {
              sections: sections,
              host_for_sitemap: 'example.com',
              pdf: {
                  page: 'pretty_path/index.html',
                  filename: 'DocGuide.pdf',
                  header: 'pretty_path/header.html'
              },
              book_repo: book
          }

          silence_io_streams do
            publisher.publish({},
                              output_paths,
                              publish_config,
                              SpecGitAccessor)
          end

          index_html = File.read File.join(final_app_dir, 'public', 'pretty_path', 'index.html')
          expect(index_html).to include 'This is a Markdown Page'

          other_index_html = File.read File.join(final_app_dir, 'public', some_other_repo.split('/').last, 'index.html')
          expect(other_index_html).to include 'This is another Markdown Page'
        end

        context 'when in local mode' do
          let(:output_paths) do
            {
              output_dir: output_dir,
              master_middleman_dir: non_broken_master_middleman_dir,
              final_app_dir: final_app_dir,
              local_repo_dir: local_repo_dir
            }
          end

          let(:publish_config) do
            {
              sections: [{'repository' => {'name' => 'my-docs-org/my-docs-repo'}}],
              host_for_sitemap: 'example.com',
              pdf: {
                  page: 'pretty_path/index.html',
                  filename: 'DocGuide.pdf',
                  header: 'pretty_path/header.html'
              },
              book_repo: book
            }
          end

          it 'it can find repos locally rather than going to github' do
            publisher.publish({}, output_paths, publish_config, SpecGitAccessor)

            index_html = File.read File.join(final_app_dir, 'public', 'my-docs-repo', 'index.html')
            expect(index_html).to include 'This is a Markdown Page'
          end

          context 'when code snippets are yielded' do
            let(:non_broken_master_middleman_dir) { generate_middleman_with 'remote_code_snippets_index.html' }

            context 'and the code repo is present' do
              it 'can find code example repos locally rather than going to github' do
                publisher.publish({},
                                  output_paths,
                                  publish_config,
                                  SpecGitAccessor)
                expect(WebMock).not_to have_requested(:any, /.*git.*/)
              end
            end

            context 'but the code repo is absent' do
              let(:local_repo_dir) { '/dev/null' }

              it 'fails out' do
                allow(logger).to receive(:log)
                expect(logger).to receive(:log).with /skipping \(not found\)/
                publisher.publish({},
                                  output_paths,
                                  publish_config,
                                  SpecGitAccessor)
                expect(WebMock).not_to have_requested(:get, 'https://api.github.com/repos/fantastic/code-example-repo/tarball/master')
              end
            end
          end
        end

        it 'generates non-broken links appropriately' do
          output_paths = {
              output_dir: output_dir,
              master_middleman_dir: dogs_master_middleman_dir,
              local_repo_dir: local_repo_dir,
              final_app_dir: final_app_dir
          }

          publish_config = {
              sections: [{'repository' => {'name' => 'org/dogs-repo'}}],
              host_for_sitemap: 'example.com',
              pdf: {
                  page: 'pretty_path/index.html',
                  filename: 'DocGuide.pdf',
                  header: 'pretty_path/header.html'
              },
              book_repo: book
          }

          no_broken_links = publisher.publish({},
                            output_paths,
                            publish_config,
                            SpecGitAccessor)

          expect(no_broken_links).to eq true
        end

        it 'includes template variables into middleman' do
          variable_master_middleman_dir = generate_middleman_with 'variable_index.html.md.erb'

          cli_options = {
              verbose: true
          }

          output_paths = {
              output_dir: output_dir,
              master_middleman_dir: variable_master_middleman_dir,
              local_repo_dir: local_repo_dir,
              final_app_dir: final_app_dir
          }

          publish_config = {
              sections: [],
              host_for_sitemap: 'example.com',
              pdf: {
                  page: 'pretty_path/index.html',
                  filename: 'DocGuide.pdf',
                  header: 'pretty_path/header.html'
              },
              book_repo: book,
              template_variables: {'name' => 'Alexander'}
          }

          publisher.publish(cli_options,
                            output_paths,
                            publish_config,
                            SpecGitAccessor)

          index_html = File.read File.join(final_app_dir, 'public', 'index.html')
          expect(index_html).to include 'My variable name is Alexander.'
        end

        describe 'including code snippets' do
          let(:section_repo_name) { 'org/dogs-repo' }
          let(:code_repo) { 'cloudfoundry/code-example-repo' }
          let(:middleman_dir) { generate_middleman_with('code_snippet_index.html.md.erb') }
          let(:cli_options) do
            {
                verbose: nil
            }
          end
          let(:output_paths) do
            {
                output_dir: output_dir,
                master_middleman_dir: middleman_dir,
                final_app_dir: final_app_dir
            }
          end
          let(:publish_config) do
            {
                sections: [{'repository' => {'name' => section_repo_name}}],
                host_for_sitemap: 'example.com',
                pdf: {
                    page: 'pretty_path/index.html',
                    filename: 'DocGuide.pdf',
                    header: 'pretty_path/header.html'
                },
                book_repo: book
            }
          end

          it 'applies the syntax highlighting CSS' do
            expect(SpecGitAccessor).to receive(:clone).with("git@github.com:#{section_repo_name}",
                                                            File.basename(section_repo_name),
                                                            anything).and_call_original
            expect(SpecGitAccessor).to receive(:clone).with("git@github.com:#{code_repo}",
                                                            File.basename(code_repo),
                                                            anything).and_call_original

            publisher.publish({}, output_paths, publish_config, SpecGitAccessor)

            index_html = File.read(File.join(final_app_dir, 'public', 'index.html'))
            doc = Nokogiri::HTML(index_html)

            ruby_part = 'fib = Enumerator.new do |yielder|'
            yaml_part = 'this_is_yaml'
            typeless_part = 'this = untyped_code'

            ruby_text = doc.css('.highlight.ruby').text
            expect(ruby_text).to include(ruby_part)
            expect(ruby_text).not_to include(yaml_part)
            expect(ruby_text).not_to include(typeless_part)

            yaml_text = doc.css('.highlight.yaml').text
            expect(yaml_text).to include(yaml_part)
            expect(yaml_text).not_to include(ruby_part)
            expect(yaml_text).not_to include(typeless_part)

            typeless_text = doc.css('.highlight.plaintext').text
            expect(typeless_text).to include(typeless_part)
            expect(typeless_text).not_to include(yaml_part)
            expect(typeless_text).not_to include(ruby_part)
          end

          it 'makes only one request per code example repository' do
            expect(SpecGitAccessor).to receive(:clone).with("git@github.com:org/dogs-repo",
                                                            "dogs-repo",
                                                            anything).and_call_original
            expect(SpecGitAccessor).to receive(:clone).with("git@github.com:cloudfoundry/code-example-repo",
                                                            "code-example-repo",
                                                            anything).and_call_original

            cli_options[:verbose] = true
            publisher.publish cli_options, output_paths, publish_config, SpecGitAccessor
          end
        end

        describe '#generate_sitemap' do
          let(:master_middleman_dir)   { dogs_master_middleman_dir }
          let(:sections) {  [{ 'repository' => {'name' => 'org/dogs-repo'} }]  }
          let(:output_paths) do
            {
                output_dir: output_dir,
                master_middleman_dir: master_middleman_dir,
                final_app_dir: final_app_dir,
                local_repo_dir: local_repo_dir
            }
          end
          let(:publish_config) do
            {
                sections: sections,
                host_for_sitemap: host_for_sitemap,
                pdf: {
                    page: 'pretty_path/index.html',
                    filename: 'DocGuide.pdf',
                    header: 'pretty_path/header.html'
                },
                book_repo: book
            }
          end

          context 'when the hostname is not a single string' do
            let(:host_for_sitemap) { ['host1.runpivotal.com', 'host2.pivotal.io'] }

            it 'raises' do
              expect do
                publisher.publish({}, output_paths, publish_config, SpecGitAccessor)
              end.to raise_error "Your public host must be a single String."
            end
          end

          context 'when the hostname is a single string' do
            let(:host_for_sitemap) { "docs.dogs.com" }

            it 'contains the given pages in an XML sitemap' do
              publisher.publish({}, output_paths, publish_config, SpecGitAccessor)

              doc = Nokogiri::XML(File.open File.join(final_app_dir, 'public', 'sitemap.xml'))
              expect(doc.css('loc').map &:text).to match_array(%w(
                http://docs.dogs.com/index.html
                http://docs.dogs.com/dogs-repo/index.html
                http://docs.dogs.com/dogs-repo/big_dogs/index.html
                http://docs.dogs.com/dogs-repo/big_dogs/great_danes/index.html
              ))
            end
          end
        end

        context "when the section's output directory has multiple levels" do
          let(:some_repo) { 'my-docs-org/my-docs-repo' }
          let(:some_sha)  { 'some-sha' }
          let(:sections) do
            {
                'repository' => {'name' => some_repo, 'ref' => some_sha}, 'directory' => 'a/b/c'
            }
          end
          let(:output_paths) do
            {
                output_dir: output_dir,
                master_middleman_dir: non_broken_master_middleman_dir,
                final_app_dir: final_app_dir,
                local_repo_dir: local_repo_dir
            }
          end
          let(:publish_config) do
            {
                sections: [sections],
                host_for_sitemap: 'example.com',
                pdf: {
                    page: 'pretty_path/index.html',
                    filename: 'DocGuide.pdf',
                    header: 'pretty_path/header.html'
                },
                book_repo: book
            }
          end

          it 'creates intermediate directories' do
            allow(GitClient).to receive(:new).and_return(git_client)
            allow(GitClient).to receive(:new).and_return(git_client)

            silence_io_streams do
              publisher.publish({}, output_paths, publish_config, SpecGitAccessor)
            end

            index_html = File.read(File.join(final_app_dir, 'public', 'a', 'b', 'c', 'index.html'))
            expect(index_html).to include('This is a Markdown Page')
          end
        end
      end

      describe 'the verbose flag' do
        include SpecHelperMethods

        before do
          allow(spider).to receive(:generate_sitemap).and_return(working_links)
          allow(spider).to receive(:has_broken_links?)
        end

        let(:local_repo_dir) { nil }
        let(:verbosity) { true }
        let(:cli_options) do
          {
              verbose: verbosity
          }
        end
        let(:output_paths) do
          {
              output_dir: output_dir,
              master_middleman_dir: generate_middleman_with('erroneous_middleman.html.md.erb'),
              final_app_dir: final_app_dir,
              local_repo_dir: local_repo_dir
          }
        end
        let(:publish_config) do
          {
              sections: [],
              host_for_sitemap: 'example.com',
              pdf: {
                  page: 'pretty_path/index.html',
                  filename: 'DocGuide.pdf',
                  header: 'pretty_path/header.html'
              },
              book_repo: 'some-repo/some-book',
              archive_menu: {}
          }
        end

        context 'when the verbose flag is not set' do
          let(:verbosity) { false }

          it 'suppresses detailed output' do
            begin
              real_stdout = $stdout
              $stdout = StringIO.new

              expect do
                publisher.publish(cli_options, output_paths, publish_config, SpecGitAccessor)
              end.to raise_error

              $stdout.rewind
              collected_output = $stdout.read

              expect(collected_output).to_not match(/error.*build\/index.html/)
              expect(collected_output).to_not match(/undefined local variable or method `function_that_does_not_exist'/)
            ensure
              $stdout = real_stdout
            end
          end
        end

        it 'shows more detailed output when the verbose flag is set' do
          begin
            real_stdout = $stdout
            $stdout = StringIO.new
            expect {
              publisher.publish cli_options, output_paths, publish_config, SpecGitAccessor
            }.to raise_error(SystemExit)

            $stdout.rewind
            collected_output = $stdout.read

            expect(collected_output).to match(/error.*build\/index.html/)
            expect(collected_output).to match(/undefined local variable or method `function_that_does_not_exist'/)
          ensure
            $stdout = real_stdout
          end
        end
      end

      context 'unit' do
        before do
          allow(spider).to receive(:generate_sitemap).and_return(working_links)
          allow(spider).to receive(:has_broken_links?)
        end

        let(:master_middleman_dir) { tmp_subdir 'irrelevant' }
        let(:pdf_config) { nil }
        let(:local_repo_dir) { nil }
        let(:book) { 'some-repo/some-book' }
        let(:sections) { [] }
        let(:host_for_sitemap) { 'example.com' }
        let(:archive_menu) { {} }
        let(:template_variables) { {} }
        let(:cli_options) do
          {
              verbose: false
          }
        end
        let(:output_paths) do
          {
              output_dir: output_dir,
              master_middleman_dir: master_middleman_dir,
              final_app_dir: final_app_dir,
              local_repo_dir: local_repo_dir
          }
        end
        let(:publish_config) do
          {
              sections: sections,
              host_for_sitemap: host_for_sitemap,
              pdf: pdf_config,
              book_repo: book,
              archive_menu: archive_menu
          }
        end

        before do
          allow(static_site_generator).to receive(:run) do |middleman_dir|
            Dir.mkdir File.join(output_dir, 'master_middleman', 'build')
          end
        end

        def publish
          publisher.publish(cli_options, output_paths, publish_config, SpecGitAccessor)
        end

        context 'when the output directory does not yet exist' do
          let(:output_dir) { File.join(Dir.mktmpdir, 'uncreated_output') }
          it 'creates the output directory' do
            publish
            expect(File.exists?(output_dir)).to eq true
          end
        end

        it 'sends middlemanRunner the correct arguments to run' do
          expect(static_site_generator).to receive(:run).with(anything,
                                                             template_variables,
                                                             local_repo_dir,
                                                             false,
                                                             anything,
                                                             sections,
                                                             host_for_sitemap,
                                                             archive_menu,
                                                             SpecGitAccessor)
          publish
        end

        it 'clears the output directory before running' do
          pre_existing_file = File.join(output_dir, 'kill_me')
          FileUtils.touch pre_existing_file
          publish
          expect(File.exists?(pre_existing_file)).to eq false
        end

        it 'clears and then copies the template_app skeleton inside final_app' do
          pre_existing_file = File.join(final_app_dir, 'kill_me')
          FileUtils.touch pre_existing_file
          publish
          expect(File.exists?(pre_existing_file)).to eq false
          copied_manifest = File.read(File.join(final_app_dir, 'app.rb'))
          template_manifest = File.read(File.join('template_app', 'app.rb'))
          expect(copied_manifest).to eq(template_manifest)
        end

        context 'when the spider reports broken links' do
          before do
            allow(spider).to receive(:has_broken_links?).and_return true
          end

          it 'returns false' do
            expect(publish).to eq false
          end
        end

        it 'returns true when everything is happy' do
          expect(publish).to eq true
        end
      end

      describe 'publishing with the version tag' do
        before do
          allow(spider).to receive(:generate_sitemap).and_return(working_links)
          allow(spider).to receive(:has_broken_links?)
        end

        let(:master_middleman_dir) { tmp_subdir 'irrelevant' }
        let(:pdf_config) { nil }
        let(:local_repo_dir) { nil }
        let(:book) { 'some-repo/some-book' }
        let(:sections) { [] }
        let(:cli_options) { {} }
        let(:output_paths) do
            {
                output_dir: output_dir,
                master_middleman_dir: master_middleman_dir,
                final_app_dir: final_app_dir,
                local_repo_dir: local_repo_dir
            }
        end
        let(:publish_config) do
          {
              sections: sections,
              host_for_sitemap: 'example.com',
              pdf: pdf_config,
              book_repo: book
          }
        end

        context 'when publishing older versions under subdirectories' do
          before do
            publish_config.merge!(
                book_repo: 'org/book',
                versions: %w(v1 v2 v3)
            )
          end

          it 'copies the previous book version index files to the middleman source dir' do
            tmp_dir_v1 = Dir.mktmpdir
            tmp_dir_v2 = Dir.mktmpdir
            tmp_dir_v3 = Dir.mktmpdir

            allow(Dir).to receive(:mktmpdir).and_call_original
            expect(Dir).to receive(:mktmpdir).with('v1').and_yield(tmp_dir_v1)
            expect(Dir).to receive(:mktmpdir).with('v2').and_yield(tmp_dir_v2)
            expect(Dir).to receive(:mktmpdir).with('v3').and_yield(tmp_dir_v3)

            book_v1 = double('Book', directory: 'book')
            expect(Book).to receive(:from_remote).with(
                                logger: logger,
                                full_name: 'org/book',
                                destination_dir: tmp_dir_v1,
                                ref: 'v1',
                                git_accessor: SpecGitAccessor) do
              SpecGitAccessor.clone('org/book', 'book', path: tmp_dir_v1).checkout('v1')
            end.and_return(book_v1)

            book_v2 = double('Book', directory: 'book')
            expect(Book).to receive(:from_remote).with(
                                logger: logger,
                                full_name: 'org/book',
                                destination_dir: tmp_dir_v2,
                                ref: 'v2',
                                git_accessor: SpecGitAccessor) do
              SpecGitAccessor.clone('org/book', 'book', path: tmp_dir_v2).checkout('v2')
            end.and_return(book_v2)

            book_v3 = double('Book', directory: 'book')
            expect(Book).to receive(:from_remote).with(
                                logger: logger,
                                full_name: 'org/book',
                                destination_dir: tmp_dir_v3,
                                ref: 'v3',
                                git_accessor: SpecGitAccessor) do
              SpecGitAccessor.clone('org/book', 'book', path: tmp_dir_v3).checkout('v3')
            end.and_return(book_v3)

            publisher.publish(cli_options, output_paths, publish_config, SpecGitAccessor)

            v1_index = File.read(
                File.join(output_dir, 'master_middleman', 'source', 'v1', 'index.html.md'))
            expect(v1_index).to eq "this is v1\n"

            v2_index = File.read(
                File.join(output_dir, 'master_middleman', 'source', 'v2', 'index.html.md'))
            expect(v2_index).to eq "this is v2\n"

            v3_index = File.read(
                File.join(output_dir, 'master_middleman', 'source', 'v3', 'index.html.md'))
            expect(v3_index).to eq "this is v3\n"
          end
        end
      end
    end
  end
end
