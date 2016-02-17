require_relative '../../../../lib/bookbinder/config/configuration'
require_relative '../../../../lib/bookbinder/config/dita_config_generator'

module Bookbinder
  module Config
    describe Configuration do
      describe '.parse' do
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

        it "parse broken link exclusions into a usable regexp" do
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

        context 'when there are dita sections' do
          it 'combines dita sections and regular sections' do
            config_generator = instance_double(DitaConfigGenerator)
            allow(DitaConfigGenerator).to receive(:new).with(
                {'repository' => {'name' => 'must/be-github'},
                  'ditamap_location' => 'example.ditamap',
                  'ditaval_location' => 'dita-filter.ditaval'}) { config_generator }
            allow(config_generator).to receive(:to_hash) { {my: 'dita-section'} }

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
            expect(config.sections[1]).to eq(Config::SectionConfig.new({my: 'dita-section'}))
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

        describe '.products' do
          it 'returns an array of ProductConfig objects' do
            config = {
              'products' => [ {'id' => 'some_product'} ]
            }
            expect(Configuration.parse(config).products[0]).to be_an_instance_of(ProductConfig)
          end
          it 'returns an empty array when no products specified' do
            config = {
              'products' => nil
            }
            expect(Configuration.parse(config).products).to eq([])
          end
          it 'passes subnav exclusion to product configs' do
            config = {
              'subnav_exclusions' => ['.class-one', '#some-id'],
              'products' => [
                { 'id' => 'some_group'}
              ]
            }

            expect(ProductConfig).to receive(:new).
                with({'id' => 'some_group', 'subnav_exclusions' => ['.class-one', '#some-id']})

            Configuration.parse(config)
          end
        end
      end
    end
  end
end
