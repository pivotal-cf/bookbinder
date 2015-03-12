require_relative '../helpers/environment_setups'
require_relative '../helpers/book_fixture'
require_relative '../helpers/application'
require_relative '../helpers/github_stub'

module Bookbinder
  describe 'binding a book with DITA sections' do

    around_in_dita_ot_env(ENV)

    context 'from local' do
      it 'processes the DITA into HTML in the output dir"' do
        application = Application.new
        dita_book = BookFixture.new('dita-book', SectionSource.local)

        application.bind_book_from_local(dita_book, silent: true) do
          it_correctly_binds_sections_in(dita_book)
        end
      end
    end

    context 'from Github' do
      it 'clones the dita sections from github, converts them into html' do
        github = GithubStub.new
        application = Application.new(github)
        dita_book = BookFixture.new('dita-book', SectionSource.remote)

        application.bind_book_from_github(dita_book, silent: true) do
          expect(github.received_clone_with_urls(
                     %w(git@github.com:my-org/my-dita-section-one
                        git@github.com:my-org/my-dita-section-two)
                 )
          ).to be_truthy

          it_correctly_binds_sections_in(dita_book)
        end
      end
    end

    def it_correctly_binds_sections_in(dita_book)
      expect(dita_book.html_files_for_dita_section('dita-section-one')).to match_array ['some-guide']
      expect(dita_book.html_files_for_dita_section('dita-section-two')).to match_array ['some-guide']

      expect(dita_book.has_frontmatter('dita-section-one')).to be_truthy
      expect(dita_book.has_frontmatter('dita-section-two')).to be_truthy

      expect(dita_book.has_applied_layout('dita-section-one')).to be_truthy
      expect(dita_book.has_applied_layout('dita-section-two')).to be_truthy

      expect(dita_book.final_images_for('dita-section-one'))
      .to match_array %w(./final_app/public/dita-section-one/images/image_one.png
                         ./final_app/public/dita-section-one/images/image_two.jpeg)
      expect(dita_book.final_images_for('dita-section-two'))
      .to match_array %w(./final_app/public/dita-section-two/images/image_one.png
                         ./final_app/public/dita-section-two/images/image_two.jpeg)

      expect(dita_book.has_dita_subnav('dita-section-one')).to be_truthy
      expect(dita_book.has_dita_subnav('dita-section-two')).to be_truthy

      expect(dita_book.exposes_subnav_links_for_js('dita-section-one')).to be_truthy
      expect(dita_book.exposes_subnav_links_for_js('dita-section-two')).to be_truthy
    end
  end
end
