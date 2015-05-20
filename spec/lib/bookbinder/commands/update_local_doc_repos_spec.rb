require_relative '../../../../lib/bookbinder/commands/update_local_doc_repos'
require_relative '../../../../lib/bookbinder/configuration'
require_relative '../../../helpers/nil_logger'
require_relative '../../../helpers/git_fake'

module Bookbinder
  describe Commands::UpdateLocalDocRepos do
    let(:config) {
      Configuration.parse('sections' => [
        {'repository' => {'name' => 'org/repo-name'}},
        {'repository' => {'name' => 'git@otherplace.com:org/repo-name-2'}},
      ])
    }
    let(:configuration_fetcher) { double('configuration_fetcher', fetch_config: config) }

    it 'updates each repo that exists on filesystem' do
      vcs = double('vcs')
      fs = double('fs')

      path_1 = File.absolute_path('../repo-name')
      path_2 = File.absolute_path('../repo-name-2')

      update = Commands::UpdateLocalDocRepos.new(double('logger').as_null_object,
                                                 configuration_fetcher,
                                                 vcs,
                                                 fs)

      allow(fs).to receive(:file_exist?).with(path_1) { false }
      allow(fs).to receive(:file_exist?).with(path_2) { true }
      expect(vcs).to receive(:update).with(path_2)

      update.run(nil)
    end

    it 'logs each pull of an existing dir, and each skip of a non-existent dir' do
      fs = double('fs')
      logger = double('deprecated logger')

      path_1 = File.absolute_path('../repo-name')
      path_2 = File.absolute_path('../repo-name-2')

      update = Commands::UpdateLocalDocRepos.new(logger,
                                                 configuration_fetcher,
                                                 double('vcs', update: nil),
                                                 fs)

      allow(fs).to receive(:file_exist?).with(path_1) { true }
      allow(fs).to receive(:file_exist?).with(path_2) { false }
      expect(logger).to receive(:log).with(/Updating.*#{path_1}/)
      expect(logger).to receive(:log).with(/skipping.*not found.*#{path_2}/)

      update.run(nil)
    end

    it 'returns 0' do
      update = Commands::UpdateLocalDocRepos.new(double('logger').as_null_object,
                                                 configuration_fetcher,
                                                 GitFake.new,
                                                 double('fs').as_null_object)
      expect(update.run(nil)).to eq(0)
    end
  end
end
