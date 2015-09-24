require_relative '../../../../lib/bookbinder/preprocessing/subnav_generator'
require_relative '../../../../lib/bookbinder/preprocessing/subnav_json_generator'
require_relative '../../../../lib/bookbinder/config/subnav_config'
require_relative '../../../../lib/bookbinder/values/output_locations'

module Bookbinder
  module Preprocessing
    describe SubnavGenerator do
      it 'passes a subnav config to a subnav json generator' do
        subnav_config = Config::SubnavConfig.new('whatever')
        output_locations = OutputLocations.new(context_dir: 'mycontextdir')

        fs = double('fs')
        json_generator = instance_double('Bookbinder::SubnavJsonGenerator')

        expect(SubnavJsonGenerator).to receive(:new) { json_generator }
        expect(json_generator).to receive(:get_links_from_config).with(subnav_config)

        SubnavGenerator.new(fs, output_locations).generate(subnav_config)
      end
    end
  end
end
