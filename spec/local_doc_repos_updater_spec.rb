require 'spec_helper'

describe LocalDocReposUpdater do

  include_context 'tmp_dirs'

  let(:local_repo_dir) { tmpdir }
  let(:repos) { [{'github_repo' => 'org/repo-name'}, {'github_repo' => 'org/repo-name-2'}] }
  let(:repo_1_dir) { File.join(local_repo_dir, 'repo-name') }
  let(:repo_2_dir) { File.join(local_repo_dir, 'repo-name-2') }
  let(:updater) { LocalDocReposUpdater.new }

  def update
    updater.update repos, local_repo_dir
  end

  context 'when the repo dirs are there' do
    before do
      Dir.mkdir repo_1_dir
      Dir.mkdir repo_2_dir
    end

    it 'issues a git pull in each repo' do
      updater.should_receive(:system).with("cd #{repo_1_dir} && git pull")
      updater.should_receive(:system).with("cd #{repo_2_dir} && git pull")
      update
    end
  end

  context 'when a repo is not there' do
    before do
      Dir.mkdir repo_1_dir
    end

    it 'does not attempt a git pull' do
      updater.should_receive(:system).with("cd #{repo_1_dir} && git pull")
      update
    end
  end

end