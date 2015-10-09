require_relative '../../../../lib/bookbinder/local_filesystem_accessor'
require_relative '../../../../lib/bookbinder/subnav/pdf_config_creator'
require_relative '../../../../lib/bookbinder/values/output_locations'
require_relative '../../../../lib/bookbinder/config/subnav_config'

module Bookbinder
  module Subnav
    describe PdfConfigCreator do
      it 'creates a yaml with a page for each link in json props file' do
        config = Config::SubnavConfig.new({'pdf_config' => 'my-pdf.yml'})
        output_locations = OutputLocations.new(context_dir: '.')

        json = { 'links' => [
                  { 'url' => '/annie/dog.html' },
                  { 'url' => '/sophie/pup.html' },
                  { 'text' => 'ignore me' },
                  { 'url' => 'yuki/pooch.html' }
               ]}.to_json

        pdf_yml = <<-EOT
---
copyright_notice: REPLACE ME
header: REPLACE ME
executable: REPLACE ME
pages:
- annie/dog.html
- sophie/pup.html
- yuki/pooch.html
        EOT

        fs = instance_double('Bookbinder::LocalFilesystemAccessor')

        expect(fs).to receive(:read).with(output_locations.subnavs_for_layout_dir.join('my-props.json')) { json }
        expect(fs).to receive(:overwrite).with(to: output_locations.pdf_config_dir.join('my-pdf.yml'), text: pdf_yml)

        PdfConfigCreator.new(fs, output_locations).create('my-props.json', config)
      end
    end
  end
end
