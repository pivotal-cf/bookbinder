require 'spec_helper'

describe Publisher do

  describe '#publish' do
    include_context 'tmp_dirs'

    let(:publisher) { Publisher.new }
    let(:output_dir) { tmp_subdir 'output' }
    let(:final_app_dir) { tmp_subdir 'final_app' }
    let(:zipped_markdown_repo) { MarkdownRepoFixture.tarball 'my-docs-repo', 'some-sha' }
    let(:other_zipped_markdown_repo) { MarkdownRepoFixture.tarball 'my-other-docs-repo', 'some-other-sha' }
    let(:non_broken_master_middleman_dir) { File.join('spec', 'fixtures', 'non_broken_master_middleman') }

    context 'integration' do

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
                          master_middleman_dir: File.join('spec', 'fixtures', 'non_broken_master_middleman'),
                          final_app_dir: final_app_dir,
                          pdf: { page: 'pretty_path/index.html',
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
        local_repo_dir = MarkdownRepoFixture.copy_to_tmp_repo_dir

        publisher.publish repos: repos,
                          output_dir: output_dir,
                          master_middleman_dir: non_broken_master_middleman_dir,
                          local_repo_dir: local_repo_dir,
                          final_app_dir: final_app_dir

        index_html = File.read File.join(final_app_dir, 'public', 'my-docs-repo', 'index.html')
        index_html.should include 'This is a Markdown Page'
      end
    end

    context 'unit' do
      let(:master_middleman_dir) { tmp_subdir 'irrelevant'}
      let(:pdf_config) { nil }
      let(:local_repo_dir) { nil }
      let(:repos) { [] }

      before do
        MiddlemanRunner.any_instance.stub(:run) {}
        Spider.any_instance.stub(:find_broken_links) {[]}
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

        before { Spider.any_instance.stub(:find_broken_links) {['one.html', 'two.html']} }

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
        let(:local_repo_dir) { Dir.mktmpdir }

        context 'when the repository used to generate the pdf was skipped' do
          let(:repos) { [ {'github_repo' => 'org/repo', 'directory' => 'pretty_dir'}] }
          let(:pdf_config) do
            {page: 'pretty_dir/index.html', filename: 'irrelevant.pdf', header: 'pretty_dir/header.html'}
          end
          it 'runs successfully' do
            expect {publish}.to_not raise_error
          end
        end

        context 'when the repository used to generate the pdf is not in the repo list' do
          let(:pdf_config) do
            {page: 'pretty_dir/index.html', filename: 'irrelevant.pdf', header: 'pretty_dir/header.html'}
          end
          it 'fails' do
            expect {publish}.to raise_error
          end
        end

        context 'when the repository used to generate the pdf is in in the repo list, but the pdf source file is not' do
          let(:repos) { [ {'github_repo' => 'org/my-docs-repo', 'directory' => 'pretty_dir'}] }
          let(:local_repo_dir) { MarkdownRepoFixture.copy_to_tmp_repo_dir }
          let(:pdf_config) do
            {page: 'pretty_dir/unknown_file.html', filename: 'irrelevant.pdf', header: 'pretty_dir/unknown_header.html'}
          end
          it 'fails' do
            expect {publish}.to raise_error
          end
        end
      end
    end
  end
end