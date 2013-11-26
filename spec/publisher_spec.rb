require 'spec_helper'

describe Publisher do

  describe '#publish' do
    include_context 'tmp_dirs'

    let(:publisher) { Publisher.new }
    let(:output_dir) { tmp_subdir 'output' }
    let(:final_app_dir) { tmp_subdir 'final_app' }
    let(:zipped_markdown_repo) { MarkdownRepoFixture.tarball 'my-docs-repo', 'some-sha' }
    let(:other_zipped_markdown_repo) { MarkdownRepoFixture.tarball 'my-other-docs-repo', 'some-other-sha' }
    let(:non_broken_master_middleman_dir) { generate_middleman_with 'non_broken_index.html' }
    let(:dogs_master_middleman_dir) { generate_middleman_with 'dogs_index.html'}

    context 'integration' do
      before { squelch_middleman_output }

      let(:local_repo_dir) { MarkdownRepoFixture.markdown_repos_dir }

      it 'it creates a directory per repo with the generated html from middleman' do
        zipped_repo_url = 'https://github.com/my-docs-org/my-docs-repo/archive/some-sha.tar.gz'
        stub_request(:get, zipped_repo_url).to_return(
            :body => zipped_markdown_repo, :headers => {'Content-Type' => 'application/x-gzip'}
        )

        other_zipped_repo_url = 'https://github.com/my-other-docs-org/my-other-docs-repo/archive/some-other-sha.tar.gz'
        stub_request(:get, other_zipped_repo_url).to_return(
            :body => other_zipped_markdown_repo, :headers => {'Content-Type' => 'application/x-gzip'}
        )

        repos = [{'github_repo' => 'my-docs-org/my-docs-repo', 'sha' => 'some-sha', 'directory' => 'pretty_path'},
                 {'github_repo' => 'my-other-docs-org/my-other-docs-repo', 'sha' => 'some-other-sha'}]
        publisher.publish repos: repos,
                          output_dir: output_dir,
                          master_middleman_dir: non_broken_master_middleman_dir,
                          final_app_dir: final_app_dir,
                          pdf: {page: 'pretty_path/index.html',
                                filename: 'DocGuide.pdf',
                                header: 'pretty_path/header.html'
                          }

        index_html = File.read File.join(final_app_dir, 'public', 'pretty_path', 'index.html')
        index_html.should include 'This is a Markdown Page'

        other_index_html = File.read File.join(final_app_dir, 'public', 'my-other-docs-repo', 'index.html')
        other_index_html.should include 'This is another Markdown Page'

        expect(File.exist? File.join(final_app_dir, 'public', 'DocGuide.pdf')).to be_true
      end

      it 'when in local mode, it can find repos locally rather than going to github' do
        repos = [{'github_repo' => 'my-docs-org/my-docs-repo'}]

        publisher.publish repos: repos,
                          output_dir: output_dir,
                          master_middleman_dir: non_broken_master_middleman_dir,
                          local_repo_dir: local_repo_dir,
                          final_app_dir: final_app_dir

        index_html = File.read File.join(final_app_dir, 'public', 'my-docs-repo', 'index.html')
        index_html.should include 'This is a Markdown Page'
      end

      it 'generates non-broken links appropriately' do
        # tests our SubmoduleAwareAssets middleman extension, which is hard to test in isolation :(
        repos = [{'github_repo' => 'org/dogs-repo'}]
        no_broken_links = publisher.publish repos: repos,
                                            output_dir: output_dir,
                                            master_middleman_dir: dogs_master_middleman_dir,
                                            local_repo_dir: local_repo_dir,
                                            final_app_dir: final_app_dir
        no_broken_links.should be_true
      end

      it 'includes template variables into middleman' do
        variable_master_middleman_dir = generate_middleman_with 'variable_index.html.md.erb'
        repos = []

        publisher.publish repos: repos,
                          output_dir: output_dir,
                          master_middleman_dir: variable_master_middleman_dir,
                          local_repo_dir: local_repo_dir,
                          final_app_dir: final_app_dir,
                          template_variables: {'name' => 'Alexander'},
                          verbose: true

        index_html = File.read File.join(final_app_dir, 'public', 'index.html')
        index_html.should include 'My variable name is Alexander.'
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

          expect { publisher.publish repos: [],
                                     output_dir: output_dir,
                                     master_middleman_dir: generate_middleman_with('erroneous_middleman.html.md.erb'),
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
      let(:repos) { [] }

      before do
        MiddlemanRunner.any_instance.stub(:run) do |middleman_dir|
          Dir.mkdir File.join(middleman_dir, 'build')
        end
        Spider.any_instance.stub(:find_broken_links) { [] }
      end

      def publish
        publisher.publish output_dir: output_dir,
                          repos: repos,
                          master_middleman_dir: master_middleman_dir,
                          final_app_dir: final_app_dir,
                          pdf: pdf_config,
                          local_repo_dir: local_repo_dir
      end

      context 'when the output directory does not yet exist' do
        let(:output_dir) { File.join(Dir.mktmpdir, 'uncreated_output') }
        it 'creates the output directory' do
          publish
          File.exists?(output_dir).should be_true
        end
      end

      it 'clear the output directory before running' do
        pre_existing_file = File.join(output_dir, 'kill_me')
        FileUtils.touch pre_existing_file
        publish
        File.exists?(pre_existing_file).should_not be_true
      end

      it 'clears and then copies the template_app skeleton inside final_app' do
        pre_existing_file = File.join(final_app_dir, 'kill_me')
        FileUtils.touch pre_existing_file
        publish
        File.exists?(pre_existing_file).should_not be_true
        copied_manifest = File.read(File.join(final_app_dir, 'app.rb'))
        template_manifest = File.read(File.join('template_app', 'app.rb'))
        expect(copied_manifest).to eq(template_manifest)
      end

      context 'when the spider reports broken links' do

        before { Spider.any_instance.stub(:find_broken_links) { ['one.html', 'two.html'] } }

        it 'reports the broken links and returns false' do
          BookbinderLogger.should_receive(:log).with(/2 broken links!/)
          result = publish
          expect(result).to be_false
        end
      end

      it 'reports if there are no broken links and returns true' do
        BookbinderLogger.should_receive(:log).with(/No broken links!/)
        result = publish
        expect(result).to be_true
      end

      context 'when asked to find repos locally' do
        let(:local_repo_dir) { MarkdownRepoFixture.markdown_repos_dir }

        context 'when the repository used to generate the pdf was skipped' do
          let(:repos) { [{'github_repo' => 'org/repo', 'directory' => 'pretty_dir'}] }
          let(:pdf_config) do
            {page: 'pretty_dir/index.html', filename: 'irrelevant.pdf', header: 'pretty_dir/header.html'}
          end
          it 'runs successfully' do
            expect { publish }.to_not raise_error
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
          let(:repos) { [{'github_repo' => 'org/my-docs-repo', 'directory' => 'pretty_dir'}] }
          let(:pdf_config) do
            {page: 'pretty_dir/unknown_file.html', filename: 'irrelevant.pdf', header: 'pretty_dir/unknown_header.html'}
          end
          it 'fails' do
            expect { publish }.to raise_error
          end
        end

      end
    end

    def generate_middleman_with(index_page)
      dir = tmp_subdir 'master_middleman'
      source_dir = File.join(dir, 'source')
      FileUtils.mkdir source_dir
      FileUtils.cp File.join('spec', 'fixtures', index_page), File.join(source_dir, 'index.html.md.erb')
      dir
    end

  end
end