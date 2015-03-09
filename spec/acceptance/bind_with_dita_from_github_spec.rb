require_relative '../helpers/environment_setups'
require_relative '../helpers/application'
require_relative '../helpers/github'
require_relative '../helpers/book_fixture'

module Bookbinder
  describe "binding from github with a book that has DITA sections" do

    around_in_dita_ot_env(ENV)

    it "clones the dita sections from github" do
      github = Github.new
      application = Application.new(github)
      dita_book = BookFixture.new('dita-book')

      application.bind_book_from_github(dita_book) do
        expect(github.received_clone_with_urls(
                   %w(git@github.com:my-org/my-dita-section-one
                      git@github.com:my-org/my-dita-section-two)
               )
        ).to be_truthy
      end
    end
  end
end