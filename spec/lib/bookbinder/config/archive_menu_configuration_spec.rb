require 'tmpdir'
require_relative '../../../../lib/bookbinder/config/archive_menu_configuration'
require_relative '../../../../lib/bookbinder/values/section'

module Bookbinder
  module Config
    describe ArchiveMenuConfiguration do
      let(:loader) { double('config loader') }
      let(:base_config) { Configuration.parse('archive_menu' => ['v2', {'v1' => 'some/place'}]) }

      context "when a section has its own menu config" do
        it "generates configuration for that section" do
          archive_config = ArchiveMenuConfiguration.new(
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
              }))
        end
      end

      context "when a section doesn't have its own menu config" do
        it "doesn't generate configuration for that section" do
          archive_config = ArchiveMenuConfiguration.new(
            loader: loader,
            config_filename: 'uncheckedfn.yml'
          )
          sections = [Section.new('not/tested', nil, nil, 'wont/appear')]

          allow(loader).to receive(:load_key) { nil }

          expect(archive_config.generate(base_config, sections)).to eq(
            Configuration.parse(
            'archive_menu' => {
              '.' => base_config.archive_menu
            }))
        end
      end
    end
  end
end
