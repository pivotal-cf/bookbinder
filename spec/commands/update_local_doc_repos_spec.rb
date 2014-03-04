require 'spec_helper'

describe Cli::UpdateLocalDocRepos do
  describe '#run' do
    let(:config_hash) { { 'repos' => [{'github_repo' => 'something'}] } }
    let(:config) { Configuration.new(config_hash) }
    let(:fake_updater) { double(update: nil) }
    before do
      LocalDocReposUpdater.stub(:new).and_return(fake_updater)
    end

    it 'returns 0' do
      expect(Cli::UpdateLocalDocRepos.new(config).run(nil)).to eq(0)
    end

    it 'calls LocalDocReposUpdater with correct params' do
      expect(fake_updater).to receive(:update).with([{'github_repo' => 'something'}], File.absolute_path('..'))
      Cli::UpdateLocalDocRepos.new(config).run(nil)
    end
  end
end
