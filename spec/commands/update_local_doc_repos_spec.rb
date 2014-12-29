require 'spec_helper'

module Bookbinder
  describe Cli::UpdateLocalDocRepos do
    describe '#run' do
      let(:sections) { [
          {'repository' => {'name' => 'org/repo-name'}},
          {'repository' => {'name' => 'org/repo-name-2'}},
      ] }
      let(:config_hash) { { 'sections' => sections } }
      let(:logger) { NilLogger.new }
      let(:config) { Configuration.new(logger, config_hash) }
      let(:configuration_fetcher) { double('configuration_fetcher') }

      before do
        allow(configuration_fetcher).to receive(:fetch_config).and_return(config)
      end

      it 'returns 0' do
        expect(Cli::UpdateLocalDocRepos.new(logger, configuration_fetcher).run(nil)).to eq(0)
      end

      it 'calls #update_local_copy on an instance of each GitHubRepository' do
        parent_directory = File.absolute_path('../')

        sections.each do |section_config|
          repository = double
          allow(GitHubRepository).to receive(:new).with(logger: logger, full_name: section_config['repository']['name'], local_repo_dir: parent_directory).and_return(repository)
          expect(repository).to receive(:update_local_copy)
        end

        Cli::UpdateLocalDocRepos.new(logger, configuration_fetcher).run(nil)
      end
    end
  end
end
