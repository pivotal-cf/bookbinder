require_relative '../../../lib/bookbinder/repositories/section_repository'
require_relative '../../../lib/bookbinder/section'
require_relative '../../helpers/tmp_dirs'
require_relative '../../helpers/nil_logger'

module Bookbinder
  describe Section do
    include_context 'tmp_dirs'

    let(:logger) { NilLogger.new }
    let(:vcs_accessor) { double('vcs_accessor') }
    let(:repository) {
      Repositories::SectionRepository.new(
        logger,
        store: {},
        build: ->(*args) { Section.new(*args) },
        git_accessor: vcs_accessor
      )
    }

    describe '#subnav_template' do
      let(:repo) { Section.new(double(:repo), subnav_template_name, 'path/to/repository') }

      context 'when the incoming template does not look like a partial file' do
        let(:subnav_template_name) { 'my_template' }

        it 'is unchanged' do
          expect(repo.subnav_template).to eq('my_template')
        end
      end

      context 'when the incoming template looks like a partial file' do
        let(:subnav_template_name) { '_my_tem.erbplate.erb' }

        it 'is trimmed' do
          expect(repo.subnav_template).to eq('my_tem.erbplate')
        end
      end

      context 'when the incoming template is not defined' do
        let(:subnav_template_name) { nil }

        it 'is nil' do
          expect(repo.subnav_template).to be_nil
        end
      end
    end

    describe '#get_modification_date_for' do
      let(:local_repo_dir) { '/some/dir' }
      let(:repo_name) { 'farm/my_cow_repo' }
      let(:vcs_accessor) { Git }
      let(:repo) { GitHubRepository.new(full_name: repo_name,
                                        local_repo_dir: local_repo_dir,
                                        git_accessor: vcs_accessor) }
      subject(:section) { Section.new(repo, 'my_template', 'path/to/farm') }
      let(:file) { 'some-file' }
      let(:git_base_object) { double Git::Base }
      let(:time) { Time.new(2011, 1, 28) }

      context 'when publishing from local' do
        before do
          allow(repo).to receive(:has_git_object?).and_return(false)
        end

        it 'creates the git object locally' do
          allow(repo).to receive(:get_modification_date_for).with(file: file, git_base_object: git_base_object).and_return(time)
          expect(vcs_accessor).to receive(:open).with(local_repo_dir+'/my_cow_repo').and_return(git_base_object)
          expect(section.get_modification_date_for(file: file)).to eq time
        end

        it 'raises if the local repo does not exist or is not a git repo' do
          allow(vcs_accessor).to receive(:open).with(local_repo_dir+'/my_cow_repo').and_raise
          expect { section.get_modification_date_for(file: file) }.
              to raise_error('Invalid git repository! Cannot get modification date for section: /some/dir/my_cow_repo.')
        end

        it 'passes the git base object to the repository' do
          allow(vcs_accessor).to receive(:open).with(local_repo_dir+'/my_cow_repo').and_return(git_base_object)
          expect(repo).to receive(:get_modification_date_for).with(file: file, git_base_object: git_base_object)
          section.get_modification_date_for(file: file)
        end
      end

      context 'when publishing from remote' do
        let(:time) { Time.new(2011, 1, 28) }

        before do
          allow(repo).to receive(:has_git_object?).and_return(true)
        end

        it 'gets the last modified date of the repository' do
          allow(repo).to receive(:get_modification_date_for).with(file: file, git_base_object: nil).and_return(time)
          expect(section.get_modification_date_for(file: file)).to eq time
        end

        it 'passes nil as the git object to the repository' do
          expect(repo).to receive(:get_modification_date_for).with(file: file, git_base_object: nil)
          section.get_modification_date_for(file: file)
        end
      end
    end
  end
end
