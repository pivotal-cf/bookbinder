require 'spec_helper'

describe Publisher do
  describe '#publish' do
    include_context 'tmp_dirs'

    let(:logger) { NilLogger.new }
    let(:publisher) { Publisher.new(logger) }
    let(:output_dir) { tmp_subdir 'output' }
    let(:final_app_dir) { tmp_subdir 'final_app' }
    let(:non_broken_master_middleman_dir) { generate_middleman_with 'non_broken_index.html' }
    let(:dogs_master_middleman_dir) { generate_middleman_with 'dogs_index.html' }
    let(:git_client) { GitClient.new(logger) }

    context 'integration' do
      before do
        squelch_middleman_output
        allow(BookbinderLogger).to receive(:new).and_return(NilLogger.new)
        WebMock.disable_net_connect!(:allow_localhost => true)
      end

      after { WebMock.disable_net_connect! }

      let(:local_repo_dir) { RepoFixture.repos_dir }

      it 'it creates a directory per repo with the generated html from middleman' do
        some_repo = 'my-docs-org/my-docs-repo'
        some_other_repo = 'my-other-docs-org/my-other-docs-repo'
        some_sha = 'some-sha'
        some_other_sha = 'some-other-sha'

        stub_github_for(git_client, some_repo, some_sha)
        stub_github_for(git_client, some_other_repo, some_other_sha)
        allow(GitClient).to receive(:new).and_return(git_client)

        sections = [
            {'repository' => {'name' => some_repo, 'ref' => some_sha}, 'directory' => 'pretty_path'},
            {'repository' => {'name' => some_other_repo, 'ref' => some_other_sha}}
        ]

        publisher.publish sections: sections, output_dir: output_dir,
                          master_middleman_dir: non_broken_master_middleman_dir,
                          final_app_dir: final_app_dir,
                          host_for_sitemap: 'example.com',
                          pdf: {
                              page: 'pretty_path/index.html',
                              filename: 'DocGuide.pdf',
                              header: 'pretty_path/header.html'
                          }

        index_html = File.read File.join(final_app_dir, 'public', 'pretty_path', 'index.html')
        expect(index_html).to include 'This is a Markdown Page'

        other_index_html = File.read File.join(final_app_dir, 'public', some_other_repo.split('/').last, 'index.html')
        expect(other_index_html).to include 'This is another Markdown Page'

        expect(File.exist? File.join(final_app_dir, 'public', 'DocGuide.pdf')).to be_true
        expect(File.exist? File.join(final_app_dir, 'public', 'FullDocSet.pdf')).to be_true
      end

      context 'when in local mode' do
        let(:publication_arguments) do
          {
              sections: [{'repository' => {'name' => 'my-docs-org/my-docs-repo'}}],
              output_dir: output_dir,
              master_middleman_dir: non_broken_master_middleman_dir,
              host_for_sitemap: 'example.com',
              local_repo_dir: local_repo_dir,
              final_app_dir: final_app_dir
          }
        end

        it 'it can find repos locally rather than going to github' do
          publisher.publish publication_arguments

          index_html = File.read File.join(final_app_dir, 'public', 'my-docs-repo', 'index.html')
          expect(index_html).to include 'This is a Markdown Page'
        end

        context 'when code snippets are yielded' do
          let(:non_broken_master_middleman_dir) { generate_middleman_with 'remote_code_snippets_index.html' }

          context 'and the code repo is present' do
            it 'can find code example repos locally rather than going to github' do
              publisher.publish publication_arguments
              expect(WebMock).not_to have_requested(:any, /.*git.*/)
            end
          end

          context 'but the code repo is absent' do
            let(:local_repo_dir) { '/dev/null' }

            it 'fails out' do
              allow(logger).to receive(:log)
              expect(logger).to receive(:log).with /skipping \(not found\)/
              publisher.publish publication_arguments
              expect(WebMock).not_to have_requested(:get, 'https://api.github.com/repos/fantastic/code-example-repo/tarball/master')
            end
          end
        end
      end

      it 'generates non-broken links appropriately' do
        # tests our SubmoduleAwareAssets middleman extension, which is hard to test in isolation :(
        sections = [{'repository' => {'name' => 'org/dogs-repo'}}]
        no_broken_links = publisher.publish sections: sections,
                                            output_dir: output_dir,
                                            master_middleman_dir: dogs_master_middleman_dir,
                                            host_for_sitemap: 'example.com',
                                            local_repo_dir: local_repo_dir,
                                            final_app_dir: final_app_dir
        expect(no_broken_links).to be_true
      end

      it 'includes template variables into middleman' do
        variable_master_middleman_dir = generate_middleman_with 'variable_index.html.md.erb'
        sections = []

        publisher.publish sections: sections,
                          output_dir: output_dir,
                          master_middleman_dir: variable_master_middleman_dir,
                          host_for_sitemap: 'example.com',
                          local_repo_dir: local_repo_dir,
                          final_app_dir: final_app_dir,
                          template_variables: {'name' => 'Alexander'},
                          verbose: true

        index_html = File.read File.join(final_app_dir, 'public', 'index.html')
        expect(index_html).to include 'My variable name is Alexander.'
      end

      describe 'including code snippets' do
        let(:section_repo_name) { 'org/dogs-repo' }
        let(:code_repo) { 'cloudfoundry/code-example-repo' }
        let(:middleman_dir) { generate_middleman_with('code_snippet_index.html.md.erb') }
        let(:publication_arguments) do
          {
              output_dir: output_dir,
              final_app_dir: final_app_dir,
              master_middleman_dir: middleman_dir,
              host_for_sitemap: 'example.com',
              sections: [{'repository' => {'name' => section_repo_name}}]
          }
        end

        it 'applies the syntax highlighting CSS' do
          stub_github_for git_client, section_repo_name
          stub_github_for git_client, code_repo
          allow(GitClient).to receive(:new).and_return(git_client)

          publisher.publish(publication_arguments)
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
          stub_github_for git_client, section_repo_name
          mock_github_for git_client, code_repo
          allow(GitClient).to receive(:new).and_return git_client

          publisher.publish publication_arguments
        end
      end

      it 'generates a sitemap' do
        sections = [{'repository' => {'name' => 'org/dogs-repo'}}]

        publisher.publish sections: sections,
                          output_dir: output_dir,
                          master_middleman_dir: dogs_master_middleman_dir,
                          local_repo_dir: local_repo_dir,
                          final_app_dir: final_app_dir,
                          host_for_sitemap: "docs.dogs.com"

        doc = Nokogiri::XML(File.open File.join(final_app_dir, 'public', 'sitemap.xml'))
        expect(doc.css('loc').map &:text).to match_array(%w(
          http://docs.dogs.com/index.html
          http://docs.dogs.com/dogs-repo/index.html
          http://docs.dogs.com/dogs-repo/big_dogs/index.html
          http://docs.dogs.com/dogs-repo/big_dogs/great_danes/index.html
        ))
      end
    end

    context 'verbose testing' do
      let(:local_repo_dir) { nil }

      it 'suppresses detailed output when the verbose flag is not set' do
        begin
          real_stdout = $stdout
          $stdout = StringIO.new

          expect { publisher.publish repos: [],
                                     output_dir: output_dir,
                                     master_middleman_dir: generate_middleman_with('erroneous_middleman.html.md.erb'),
                                     host_for_sitemap: 'example.com',
                                     local_repo_dir: local_repo_dir,
                                     final_app_dir: final_app_dir,
                                     verbose: false }.to raise_error

          $stdout.rewind
          collected_output = $stdout.read

          expect(collected_output).to_not match(/== Building files/)
          expect(collected_output).to_not match(/== Request: \/index.html/)
          expect(collected_output).to_not match(/error.*build\/index.html/)
          expect(collected_output).to_not match(/undefined local variable or method `function_that_does_not_exist'/)
        ensure
          $stdout = real_stdout
        end
      end

      it 'shows more detailed output when the verbose flag is set' do
        begin
          real_stdout = $stdout
          $stdout = StringIO.new

          expect { publisher.publish sections: [],
                                     output_dir: output_dir,
                                     master_middleman_dir: generate_middleman_with('erroneous_middleman.html.md.erb'),
                                     host_for_sitemap: 'example.com',
                                     local_repo_dir: local_repo_dir,
                                     final_app_dir: final_app_dir,
                                     verbose: true }.to raise_error

          $stdout.rewind
          collected_output = $stdout.read

          expect(collected_output).to match(/== Building files/)
          expect(collected_output).to match(/== Request: \/index.html/)
          expect(collected_output).to match(/error.*build\/index.html/)
          expect(collected_output).to match(/undefined local variable or method `function_that_does_not_exist'/)
        ensure
          $stdout = real_stdout
        end
      end
    end

    context 'unit' do
      let(:master_middleman_dir) { tmp_subdir 'irrelevant' }
      let(:pdf_config) { nil }
      let(:local_repo_dir) { nil }
      let(:sections) { [] }
      let(:working_links) { [] }
      let(:spider) { double(:eight_legger) }

      before do
        MiddlemanRunner.any_instance.stub(:run) do |middleman_dir|
          Dir.mkdir File.join(middleman_dir, 'build')
        end
        allow(spider).to receive(:generate_sitemap).and_return(working_links)
        allow(spider).to receive(:has_broken_links?)
      end

      def publish
        publisher.publish output_dir: output_dir,
                          sections: sections,
                          master_middleman_dir: master_middleman_dir,
                          host_for_sitemap: 'example.com',
                          final_app_dir: final_app_dir,
                          pdf: pdf_config,
                          local_repo_dir: local_repo_dir,
                          spider: spider
      end

      context 'when the output directory does not yet exist' do
        let(:output_dir) { File.join(Dir.mktmpdir, 'uncreated_output') }
        it 'creates the output directory' do
          publish
          expect(File.exists?(output_dir)).to be_true
        end
      end

      it 'clears the output directory before running' do
        pre_existing_file = File.join(output_dir, 'kill_me')
        FileUtils.touch pre_existing_file
        publish
        expect(File.exists?(pre_existing_file)).to be_false
      end

      it 'clears and then copies the template_app skeleton inside final_app' do
        pre_existing_file = File.join(final_app_dir, 'kill_me')
        FileUtils.touch pre_existing_file
        publish
        expect(File.exists?(pre_existing_file)).to be_false
        copied_manifest = File.read(File.join(final_app_dir, 'app.rb'))
        template_manifest = File.read(File.join('template_app', 'app.rb'))
        expect(copied_manifest).to eq(template_manifest)
      end

      context 'when the spider reports broken links' do
        before { spider.stub(:has_broken_links?).and_return true }

        it 'returns false' do
          expect(publish).to be_false
        end
      end

      it 'returns true when everything is happy' do
        expect(publish).to be_true
      end

      context 'when asked to find repos locally' do
        let(:local_repo_dir) { RepoFixture.repos_dir }

        around do |example|
          WebMock.disable_net_connect!(:allow_localhost => true)
          example.run
          WebMock.disable_net_connect!
        end

        context 'when the repository used to generate the pdf was skipped' do
          let(:sections) { [{'repository' => {'name' => 'org/repo'}, 'directory' => 'pretty_dir'}] }
          let(:pdf_config) do
            {page: 'pretty_dir/index.html', filename: 'irrelevant.pdf', header: 'header.html'}
          end

          context 'but the header is available' do
            before do
              stub_request(:get, "http://localhost:41722/header.html").
                  to_return(:status => 200, :body => 'eggplant', :headers => {})
            end

            context 'but there are no links' do
              let(:working_links) { [] }

              it 'runs successfully' do
                expect { publish }.to_not raise_error
              end
            end

            context 'when there are some working links' do
              let(:working_links) { %w(http://example.com/working.htm http://example.com/hard.htm) }

              before do
                working_links.each do |link|
                  stub_request(:get, link).to_return(:status => 200, :body => rand(10_000), :headers => {})
                end
              end

              it 'runs successfully' do
                expect { publish }.to_not raise_error
              end
            end
          end
        end

        context 'when the repository used to generate the pdf is not in the repo list' do
          let(:pdf_config) do
            {page: 'pretty_dir/index.html', filename: 'irrelevant.pdf', header: 'pretty_dir/header.html'}
          end
          it 'fails' do
            expect { publish }.to raise_error
          end
        end

        context 'when the repository used to generate the pdf is in in the repo list, but the pdf source file is not' do
          let(:sections) { [{'repository' => {'name' => 'org/my-docs-repo'}, 'directory' => 'pretty_dir'}] }
          let(:pdf_config) do
            {page: 'pretty_dir/unknown_file.html', filename: 'irrelevant.pdf', header: 'pretty_dir/unknown_header.html'}
          end

          it 'fails' do
            expect { publish }.to raise_error PdfGenerator::MissingSource
          end
        end
      end
    end
  end
end
