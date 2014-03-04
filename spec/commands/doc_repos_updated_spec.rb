require 'spec_helper'

describe Cli::DocReposUpdated do
  describe '#run' do
    let(:book_repo) { 'book_repo' }
    let(:repos) { 'repos' }
    let(:config_hash) do
      {
        'book_repo' => book_repo,
        'repos' => repos
      }
    end
    let(:config) { Configuration.new(config_hash) }

    let(:fake_book) { double }
    let(:fake_change_monitor) { double }

    let(:doc_repos_updated) { Cli::DocReposUpdated.new(config) }

    before do
      Book.stub(:new).with(full_name: book_repo, constituent_params: repos).and_return(fake_book)
      DocRepoChangeMonitor.stub(:new).with(fake_book).and_return(fake_change_monitor)
    end

    context 'when ChangeMonitor reports a build is necessary' do
      before do
        fake_change_monitor.stub(:build_necessary?).and_return(true)
      end

      it 'returns 0' do
        expect(doc_repos_updated.run(nil)).to eq(0)
      end
    end

    context 'when ChangeMonitor reports a build is not necessary' do
      before do
        fake_change_monitor.stub(:build_necessary?).and_return(false)
      end

      it 'returns 42' do
        expect(doc_repos_updated.run(nil)).to eq(42)
      end
    end
  end
end
