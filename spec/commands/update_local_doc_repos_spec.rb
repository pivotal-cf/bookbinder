require 'spec_helper'

describe Cli::UpdateLocalDocRepos do
  describe '#run' do
    let(:sections) { [
        {'repository' => {'name' => 'org/repo-name'}},
        {'repository' => {'name' => 'org/repo-name-2'}},
    ] }
    let(:config_hash) { { 'sections' => sections } }
    let(:config) { Configuration.new(config_hash) }

    it 'returns 0' do
      expect(Cli::UpdateLocalDocRepos.new(config).run(nil)).to eq(0)
    end

    it 'calls #update_local_copy on an instance of each Repository' do
      parent_directory = File.absolute_path('../')

      sections.each do |section_config|
        repository = double
        allow(Repository).to receive(:new).with(full_name: section_config['repository']['name'], local_repo_dir: parent_directory).and_return(repository)
        expect(repository).to receive(:update_local_copy)
      end

      Cli::UpdateLocalDocRepos.new(config).run(nil)
    end
  end
end
