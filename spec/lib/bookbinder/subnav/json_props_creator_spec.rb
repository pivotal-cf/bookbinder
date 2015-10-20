require_relative '../../../../lib/bookbinder/local_filesystem_accessor'
require_relative '../../../../lib/bookbinder/subnav/json_props_creator'
require_relative '../../../../lib/bookbinder/values/output_locations'
require_relative '../../../../lib/bookbinder/config/subnav_config'

module Bookbinder
  module Subnav
    describe JsonPropsCreator do
      it 'gets the toc links from json generator and writes them to a props file' do
        fs = instance_double('Bookbinder::LocalFilesystemAccessor')
        json_generator = instance_double('Bookbinder::Preprocessing::JsonFromConfig')

        output_locations = OutputLocations.new(context_dir: '.')
        subnav_config = Config::SubnavConfig.new({'name' => 'best'})

        props_filename = 'best-props.json'
        props_location = output_locations.subnavs_for_layout_dir.join(props_filename)

        expect(json_generator).to receive(:get_links).with(subnav_config, output_locations) { 'toc text' }
        expect(fs).to receive(:write).with(text: 'toc text', to: props_location)

        expect(JsonPropsCreator.new(fs, output_locations, json_generator).create(subnav_config)).
          to eq(props_filename)
      end

      it 'returns different names for different subnavs' do
        fs = instance_double('Bookbinder::LocalFilesystemAccessor')
        json_generator = instance_double('Bookbinder::Preprocessing::JsonFromConfig')

        output_locations = OutputLocations.new(context_dir: '.')
        config_one = Config::SubnavConfig.new({'name' => 'best'})
        config_two = Config::SubnavConfig.new({'name' => 'worst'})

        props_location = output_locations.subnavs_for_layout_dir

        allow(json_generator).to receive(:get_links) { 'toc text' }
        allow(fs).to receive(:write).with(text: 'toc text', to: props_location.join('best-props.json'))
        allow(fs).to receive(:write).with(text: 'toc text', to: props_location.join('worst-props.json'))

        creator = JsonPropsCreator.new(fs, output_locations, json_generator)
        expect(creator.create(config_one)).to eq('best-props.json')
        expect(creator.create(config_two)).to eq('worst-props.json')
      end
    end
  end
end
