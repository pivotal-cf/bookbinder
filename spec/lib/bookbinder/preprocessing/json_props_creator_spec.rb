require_relative '../../../../lib/bookbinder/local_filesystem_accessor'
require_relative '../../../../lib/bookbinder/preprocessing/json_props_creator'
require_relative '../../../../lib/bookbinder/values/output_locations'
require_relative '../../../../lib/bookbinder/config/subnav_config'

module Bookbinder
  module Preprocessing
    describe JsonPropsCreator do
      it 'gets the toc links from json generator and writes them to a props file' do
        fs = instance_double('Bookbinder::LocalFilesystemAccessor')
        json_generator = instance_double('Bookbinder::Preprocessing::JsonFromConfig')

        output_locations = OutputLocations.new(context_dir: '.')
        subnav_config = Config::SubnavConfig.new({'name' => 'best'})

        props_location = output_locations.subnavs_for_layout_dir.join('best-subnav-props.json')

        expect(json_generator).to receive(:generate).with(subnav_config) { 'toc text' }
        expect(fs).to receive(:write).with(text: 'toc text', to: props_location)

        expect(JsonPropsCreator.new(fs, output_locations, json_generator).create(subnav_config)).
          to eq(props_location)
      end
    end
  end
end
