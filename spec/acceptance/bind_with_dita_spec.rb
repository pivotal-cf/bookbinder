require_relative '../helpers/environment_setups'
require_relative '../helpers/book_fixture'
require_relative '../helpers/application'
require_relative '../helpers/git_fake'

module Bookbinder
  describe 'binding a book with DITA sections' do

    around_in_dita_ot_env(ENV)

    context 'from local' do
      it 'processes the DITA into HTML in the output dir' do
        application = Application.new
        dita_book = BookFixture.new('dita-book', SectionSource.local)

        application.bind_book_from_local(dita_book, silent: true) do
          it_correctly_binds_sections_in(dita_book)
        end
      end
    end

    context 'from Github' do
      it 'clones the dita sections from github, converts them into html, including .ditaval variables' do
        github = GitFake.new
        application = Application.new(github)
        dita_book = BookFixture.new('dita-book', SectionSource.remote)

        application.bind_book_from_github(dita_book, silent: true) do
          expect(github.received_clone_with_urls(
                     %w(git@github.com:my-org/dita-section-one
                        git@github.com:my-org/dita-section-dependency)
                 )
          ).to be_truthy

          it_correctly_binds_sections_in(dita_book)
        end
      end
    end

    context 'when binding different refs of the same dita section' do
      context 'and the section contains a ditamap' do
        it 'should create a subdirectory for each dita section' do
          application = Application.new
          dita_book = BookFixture.new('dita-book-with-multiple-refs-of-the-same-section', SectionSource.remote)

          application.bind_book_from_github(dita_book, silent: true) do
            it_correctly_binds_multiple_ditamaps_from(dita_book)
          end
        end
      end
    end

    context 'when passing DITA options at the command line' do
      context 'such as args.copycss' do
        it 'it invokes DITA-OT with that option' do
          application = Application.new
          dita_book = BookFixture.new('dita-book', SectionSource.local)
          dita_options = "args.copycss='yes' " +
                         "args.css='master.css' " +
                         "args.cssroot='#{File.absolute_path '../fixtures/repositories/dita-book/master_middleman/source/stylesheets/', __dir__} " +
                         "args.csspath='./copied_stylesheets/' "
          application.bind_book_with_dita_options(dita_book,
                                                  silent: true,
                                                  dita_options: dita_options,
                                                  ) do
            it_correctly_binds_sections_in(dita_book)
            it_correctly_invokes_dita_options(dita_book, dita_options)
          end
        end
      end
    end

    def it_correctly_binds_multiple_ditamaps_from(dita_book)
      dita_section_at_ref_one = DitaSectionData.new('dita-section-one',
                                                    'my-dita-section-at-v-one')
      dita_section_at_ref_two = DitaSectionData.new('dita-section-one',
                                                    'my-dita-section-at-v-two')

      expect(dita_book.html_files_for_dita_section(dita_section_at_ref_one)).
          to match_array ['some-guide-v-one', '../dita-section-dependency/some-guide-1']

      expect(dita_book.html_files_for_dita_section(dita_section_at_ref_two)).
          to match_array ['some-guide-v-two', '../dita-section-dependency/some-guide-1']
    end

    def it_correctly_binds_sections_in(dita_book)
      dita_section_one = DitaSectionData.new('dita-section-one',
                                             'my-renamed-dita-section-one')
      dita_section_dependency = DitaSectionData.new('dita-section-dependency',
                                                    'dita-section-dependency')

      expect(dita_book.html_files_for_dita_section(dita_section_one)).
          to match_array ['some-guide', '../dita-section-dependency/some-guide-1']

      expect(dita_book.has_frontmatter(dita_section_one)).to be_truthy

      expect(dita_book.has_applied_layout(dita_section_one)).to be_truthy

      expect(dita_book.uses_dita_filtered_values(dita_section_one,
                                                'Include-me!',
                                                'Exclude-me!')).to be_truthy

      expect(dita_book.final_images_for(dita_section_one))
      .to match_array %w(./final_app/public/my-renamed-dita-section-one/image_one.png
                         ./final_app/public/my-renamed-dita-section-one/images/image_two.jpeg)

      expect(dita_book.final_images_for(dita_section_dependency))
      .to match_array %w(./final_app/public/dita-section-dependency/image_one_dependency.jpeg
                         ./final_app/public/dita-section-dependency/images/image_two_dependency.png)

      expect(dita_book.has_dita_subnav(dita_section_one)).to be_truthy

      expect(dita_book.exposes_subnav_links_for_js).to be_truthy
    end

    def it_correctly_invokes_dita_options(dita_book, dita_options)
      dita_section_one = DitaSectionData.new('dita-section-one',
                                             'my-renamed-dita-section-one')

      expect(dita_book.invokes_dita_option_for_css_path(dita_section_one, dita_options)).to be_truthy
    end

    DitaSectionData = Struct.new(:repo_name, :dir)
  end
end
