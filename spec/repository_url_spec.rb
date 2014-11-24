require 'spec_helper'

module Bookbinder
  describe Repository do
    include_context 'tmp_dirs'

    describe '#get_repo_url' do
      let(:logger) { NilLogger.new }
      let(:github_repo_double) { double Octokit::Repository }
      let(:git_client) { double GitClient }
      let(:access_token) { 'foo' }

      class FakeRels
        def href
          "https://github.com/org/repo"
        end
      end

      before do
        allow(github_repo_double).to receive(:rels).and_return({clone: FakeRels.new})
        allow(GitClient).to receive(:new).and_return(git_client)
        allow(git_client).to receive(:repository).and_return(github_repo_double)
      end

      context 'if there is an access token' do
        let(:repo) { Repository.new(logger: logger, full_name: "org/repo", target_ref: "sha",
                                    github_token: access_token) }


        it 'inserts oauth basic user and pass' do

          allow(git_client).to receive(:access_token).and_return(access_token)
          expect(repo.get_repo_url("org/repo")).to eq("https://foo:x-oauth-basic@github.com/org/repo")
        end
      end

      context 'when there is no api token' do
        let(:repo) { Repository.new(logger: logger, full_name: "org/repo") }

        it 'inserts nothing into the URL' do
          allow(git_client).to receive(:access_token).and_return(nil)
          expect(repo.get_repo_url("org/repo")).to eq("https://github.com/org/repo")
        end
      end
    end
  end
end