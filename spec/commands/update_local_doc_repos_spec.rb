require 'spec_helper'

describe Cli::UpdateLocalDocRepos do
  describe '#run' do
    let(:repo_configs) { [{'github_repo' => 'org/repo-name'}, {'github_repo' => 'org/repo-name-2'}] }
    let(:config_hash) { { 'repos' => repo_configs } }
    let(:config) { Configuration.new(config_hash) }

    it 'returns 0' do
      expect(Cli::UpdateLocalDocRepos.new(config).run(nil)).to eq(0)
    end

    it 'calls #update_local_copy on an instance of each Repository' do
      parent_directory = File.absolute_path('../')

      repo_configs.each do |repo_config|
        repository = double
        allow(Repository).to receive(:new).with(full_name: repo_config['github_repo'], local_repo_dir: parent_directory).and_return(repository)
        expect(repository).to receive(:update_local_copy)
      end

      Cli::UpdateLocalDocRepos.new(config).run(nil)
    end
  end
end
