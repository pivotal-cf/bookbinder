require 'tmpdir'
require_relative '../../../lib/bookbinder/archive_menu_configuration'
require_relative '../../../lib/bookbinder/section'

module Bookbinder
  describe ArchiveMenuConfiguration do
    let(:loader) { double('config loader') }
    let(:base_config) { { archive_menu: ['v2', {'v1' => 'some/place'}] } }

    context "when a section has its own menu config" do
      it "generates configuration for that section" do
        archive_config = ArchiveMenuConfiguration.new(
          loader: loader,
          config_filename: 'iampresent.yml'
        )
        dir = 'some/path'
        sections = [Section.new(dir, nil, nil, nil, nil, 'my/dir')]

        allow(loader).
          to receive(:load_key).
          with(Pathname(dir).join('iampresent.yml'), 'archive_menu') {
            ['v1', {'v0.9' => 'section/place'}]
          }

        expect(archive_config.generate(base_config, sections)).to eq(
          archive_menu: {
            '.' => base_config[:archive_menu],
            'my/dir' => ['v1', {'v0.9' => 'section/place'}]
          }
        )
      end
    end

    context "when a section doesn't have its own menu config" do
      it "doesn't generate configuration for that section" do
        archive_config = ArchiveMenuConfiguration.new(
          loader: loader,
          config_filename: 'uncheckedfn.yml'
        )
        sections = [Section.new('not/tested', nil, nil, nil, nil, 'wont/appear')]

        allow(loader).to receive(:load_key) { nil }

        expect(archive_config.generate(base_config, sections)).to eq(
          archive_menu: {
            '.' => base_config[:archive_menu]
          }
        )
      end
    end
  end
end
