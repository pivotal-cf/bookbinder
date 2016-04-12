require_relative '../../../../lib/bookbinder/commands/update_local_doc_repos'
require_relative '../../../../lib/bookbinder/config/configuration'
require_relative '../../../../lib/bookbinder/ingest/update_failure'
require_relative '../../../../lib/bookbinder/ingest/update_success'
require_relative '../../../helpers/git_fake'

module Bookbinder
  describe Commands::UpdateLocalDocRepos do
    let(:config) {
      Config::Configuration.parse('sections' => [
        {'repository' => {'name' => 'org/repo-name'}},
        {'repository' => {'name' => 'git@otherplace.com:org/repo-name-2'}},
      ])
    }
    let(:configuration_fetcher) { double('configuration_fetcher', fetch_config: config) }

    it 'updates each repo' do
      vcs = double('vcs')
      fs = double('fs')

      path_1 = File.absolute_path('../repo-name')
      path_2 = File.absolute_path('../repo-name-2')

      update = Commands::UpdateLocalDocRepos.new(
        {success: StringIO.new, out: StringIO.new},
        configuration_fetcher,
        vcs
      )

      expect(vcs).to receive(:update).with(path_1) { Ingest::UpdateSuccess.new }
      expect(vcs).to receive(:update).with(path_2) { Ingest::UpdateSuccess.new }

      update.run
    end

    it 'logs each successful pull, and each skip of an unsuccessful pull' do
      path_1 = File.absolute_path('../repo-name')
      path_2 = File.absolute_path('../repo-name-2')

      out = StringIO.new
      success = StringIO.new
      vcs = double('vcs')

      update = Commands::UpdateLocalDocRepos.new(
        {success: success, out: out},
        configuration_fetcher,
        vcs
      )

      not_found = Ingest::UpdateFailure.new('potatoes')
      allow(vcs).to receive(:update).with(path_1) { Ingest::UpdateSuccess.new }
      allow(vcs).to receive(:update).with(path_2) { not_found }

      update.run

      expect(out.tap(&:rewind).read).to eq(<<-MESSAGE)

Updating #{path_1}:
Updating #{path_2}: skipping (potatoes)
      MESSAGE

      expect(success.tap(&:rewind).read).to eq(' updated')
    end

    it 'returns 0' do
      update = Commands::UpdateLocalDocRepos.new({out: StringIO.new,
                                                  success: StringIO.new},
                                                  configuration_fetcher,
                                                  double('vcs', update: Ingest::UpdateSuccess.new))
      expect(update.run).to eq(0)
    end
  end
end
