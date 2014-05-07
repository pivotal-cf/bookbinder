require 'spec_helper'

module Bookbinder
  describe Cli::DocReposUpdated do
    describe '#run' do
      let(:book_repo) { 'book_repo' }
      let(:sections) { [] }
      let(:config_hash) do
        {
            'book_repo' => book_repo,
            'sections' => sections
        }
      end

      let(:logger) { NilLogger.new }
      let(:config) { Configuration.new(logger, config_hash) }

      let(:fake_book) { double }
      let(:fake_change_monitor) { double }

      let(:doc_repos_updated) { Cli::DocReposUpdated.new(logger, config) }

      before do
        fake_book = expect_to_receive_and_return_real_now(Book, :new, logger: logger, full_name: book_repo, sections: sections)
        allow(DocRepoChangeMonitor).to receive(:new).with(logger, fake_book).and_return(fake_change_monitor)
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
          allow(fake_change_monitor).to receive(:build_necessary?).and_return(false)
        end

        it 'returns 42' do
          expect(doc_repos_updated.run(nil)).to eq(42)
        end
      end
    end
  end
end