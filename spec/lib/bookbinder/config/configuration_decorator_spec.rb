require 'tmpdir'
require_relative '../../../../lib/bookbinder/config/configuration_decorator'
require_relative '../../../../lib/bookbinder/values/section'

module Bookbinder
  module Config
    describe ConfigurationDecorator do
      let(:loader) { double('config loader') }
      let(:base_config) { Configuration.parse('archive_menu' => ['v2', {'v1' => 'some/place'}]) }

      context "when dir_repo_links are enabled" do
        it "generates configuration mapping section desired dirs to repo names" do
          config_decorator = ConfigurationDecorator.new(loader: loader, config_filename: 'iampresent.yml')
          base_config = Configuration.parse('dir_repo_link_enabled' => true)
          sections = [Section.new('must/be-github', nil, 'go here!!!')]
          expected_config = Configuration.parse(
            'dir_repo_link_enabled' => true,
            'dir_repo_links' => ['go here!!!' => 'must/be-github'],
            'archive_menu' => {
              '.' => nil
            }
          )
          allow(loader).to receive(:load_key).
              with(Pathname('must/be-github').join('iampresent.yml'), 'github_link_enabled') { true }
          allow(loader).to receive(:load_key).
              with(Pathname('must/be-github').join('iampresent.yml'), 'archive_menu') {}

          expect((config_decorator).generate(base_config, sections)).to eq(expected_config)
        end
      end

      context "when a section has its own menu config" do
        it "generates configuration for that section" do
          archive_config = ConfigurationDecorator.new(
            loader: loader,
            config_filename: 'iampresent.yml'
          )
          dir = 'some/path'
          sections = [Section.new(dir, nil, 'my/dir')]

          allow(loader).
            to receive(:load_key).
            with(Pathname(dir).join('iampresent.yml'), 'archive_menu') {
              ['v1', {'v0.9' => 'section/place'}]
            }

          expect(archive_config.generate(base_config, sections)).to eq(
            Configuration.parse(
              'archive_menu' => {
                '.' => base_config.archive_menu,
                'my/dir' => ['v1', {'v0.9' => 'section/place'}]
              },
              'dir_repo_links' => nil
            ))
        end
      end

      context "when a section doesn't have its own menu config" do
        it "doesn't generate configuration for that section" do
          archive_config = ConfigurationDecorator.new(
            loader: loader,
            config_filename: 'uncheckedfn.yml'
          )
          sections = [Section.new('not/tested', nil, nil, 'wont/appear')]

          allow(loader).to receive(:load_key) { nil }

          expect(archive_config.generate(base_config, sections)).to eq(
            Configuration.parse(
            'archive_menu' => {
              '.' => base_config.archive_menu
            },
            'dir_repo_links' => nil))
        end
      end
    end
  end
end
