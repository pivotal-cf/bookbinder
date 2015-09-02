require_relative '../../../../lib/bookbinder/config/configuration'

module Bookbinder
  module Config
    describe Configuration do
      it "can return fully formed git URLs, defaulting to GitHub" do
        config = Configuration.parse(
          'book_repo' => 'some-org/some-repo',
          'cred_repo' => 'git@bitbucket.org:my/private-cred-repo',
          'layout_repo' => 'git@bitbucket.org:my/private-layout-repo',
          'sections' => [
            {'repository' => {'name' => 'must/be-github'}},
            {'repository' => {'name' => 'git@bitbucket.org:another/bitbucket-repo'}},
            {'repository' => {'name' => 'https://github.com/over/https'}},
          ],
        )
        expect(config.book_repo_url).to eq("git@github.com:some-org/some-repo")
        expect(config.cred_repo_url).to eq("git@bitbucket.org:my/private-cred-repo")
        expect(config.layout_repo_url).to eq("git@bitbucket.org:my/private-layout-repo")
        expect(config.sections[0].repo_url).to eq('git@github.com:must/be-github')
        expect(config.sections[1].repo_url).to eq('git@bitbucket.org:another/bitbucket-repo')
        expect(config.sections[2].repo_url).to eq('https://github.com/over/https')

        expect(Configuration.parse('book_repo' => 'git@amazon.place:some-org/some-repo').book_repo_url).
          to eq('git@amazon.place:some-org/some-repo')
      end

      it "parses broken link exclusions into a usable regexp" do
        config = Configuration.parse(
          'broken_link_exclusions' => '[a-c]'
        )
        expect('a').to match(config.broken_link_exclusions)
        expect('d').not_to match(config.broken_link_exclusions)
      end

      it "can match a string against undefined broken link exclusions" do
        config = Configuration.parse({})
        expect('a').not_to match(config.broken_link_exclusions)
        expect('d').not_to match(config.broken_link_exclusions)
      end

      it "can merge another config object" do
        expect(Configuration.parse('book_repo' => 'foo/bar',
                                   'cred_repo' => 'cred/repo',
                                   'template_variables' => {'a' => 'b'},
                                   'versions' => []).
                                   merge(Configuration.parse('book_repo' => 'baz/qux', 'versions' => ['thing']))).
        to eq(Configuration.parse('book_repo' => 'baz/qux',
                                  'cred_repo' => 'cred/repo',
                                  'template_variables' => {'a' => 'b'},
                                  'versions' => ['thing']))
      end

      it "exposes the public_host" do
        expect(Configuration.parse('public_host' => 'foo.bar').public_host).to eq('foo.bar')
      end

      context "when there are dita sections" do
        it "combines dita sections and regular sections" do
          config = Configuration.parse(
            'sections' => [
              {'repository' => {'name' => 'must/be-github'}},
            ],
            'dita_sections' => [
              {'repository' => {'name' => 'must/be-github'},
                'ditamap_location' => 'example.ditamap',
                'ditaval_location' => 'dita-filter.ditaval'}
            ]
          )
          expect(config.sections.size).to eq(2)
          expect(config.sections[1]).to eq(
              Config::SectionConfig.new(
                'repository' => {'name' => 'must/be-github'},
                'preprocessor_config' => {
                  'ditamap_location' => 'example.ditamap',
                  'ditaval_location' => 'dita-filter.ditaval'
                },
                'subnav_template' => 'dita_subnav'
              )
            )
        end

        context "with one ditamap" do
          it "uses the default dita subnav template" do
            config = Configuration.parse(
              'dita_sections' => [
                {'repository' => {'name' => 'org/repo-name'},
                 'ditamap_location' => 'first-ditamap-location'}
              ]
            )
            expect(config.sections[0].subnav_template).to eq('dita_subnav')
          end
        end

        context "when a DITA section doesn't have a ditamap" do
          it "takes its subnav template from the first DITA section with a ditamap" do
            config = Configuration.parse(
              'dita_sections' => [
                {'repository' => {'name' => 'org/repo-name1'},
                 'ditamap_location' => 'first-ditamap-location'},
                {'repository' => {'name' => 'another-org/repo-name2'}},
              ]
            )
            expect(config.sections[0].subnav_template).to eq('dita_subnav')
            expect(config.sections[1].subnav_template).to eq('dita_subnav')
          end
        end
      end

      it 'returns nil when optional keys do not exist' do
        config = Configuration.parse({})
        expect(config.archive_menu).to be_nil
      end

      it 'returns an empty hash when template_variables is not provided' do
        config = Configuration.parse({})
        expect(config.template_variables).to eq({})
      end

      describe 'equality' do
        it 'is true for identical configurations' do
          expect(Configuration.new(book_repo_url: 'a',
                                   cred_repo_url: 'b',
                                   layout_repo_url: 'c',
                                   sections: ['d'],
                                   template_variables: {},
                                   versions: %w(v1 v2))).
          to eq(Configuration.new(book_repo_url: 'a',
                                  cred_repo_url: 'b',
                                  layout_repo_url: 'c',
                                  sections: ['d'],
                                  template_variables: {},
                                  versions: %w(v1 v2)))
        end

        it 'is false for different configurations' do
          expect(Configuration.new(book_repo_url: 'a',
                                   cred_repo_url: 'b',
                                   layout_repo_url: 'c',
                                   sections: ['d'],
                                   template_variables: {},
                                   versions: %w(v1 v2))).
          not_to eq(Configuration.new(book_repo_url: 'z',
                                      cred_repo_url: 'z',
                                      layout_repo_url: 'c',
                                      sections: ['d'],
                                      template_variables: {},
                                      versions: %w(v1 v2)))
        end
      end

      it 'can report on whether options are available' do
        config = Configuration.new(book_repo_url: 'bar')
        expect(config).to have_option('book_repo_url')
        expect(config).not_to have_option('bar')
      end
    end
  end
end
