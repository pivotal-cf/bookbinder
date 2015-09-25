require_relative '../../../../lib/bookbinder/preprocessing/json_props_creator'
require_relative '../../../../lib/bookbinder/preprocessing/subnav_generator'
require_relative '../../../../lib/bookbinder/preprocessing/subnav_generator_factory'
require_relative '../../../../lib/bookbinder/preprocessing/template_creator'
require_relative '../../../../lib/bookbinder/values/output_locations'

module Bookbinder
  module Preprocessing
    describe SubnavGeneratorFactory do
      describe 'produce' do
        it 'returns a subnav generator' do
          json_generator = double('json generator')
          fs = double('local filesystem accessor')
          json_props_creator = double('json props creator')
          template_creator = double('template creator')
          subnav_generator = double('subnav generator')

          output_locations = OutputLocations.new(context_dir: '.')
          factory = Preprocessing::SubnavGeneratorFactory.new(fs, output_locations)

          allow(JsonPropsCreator).to receive(:new).with(fs, output_locations, json_generator) { json_props_creator }
          allow(TemplateCreator).to receive(:new).with(fs, output_locations) { template_creator }

          expect(SubnavGenerator).to receive(:new).with(fs, output_locations, json_props_creator, template_creator) { subnav_generator }
          expect(factory.produce(json_generator)).to be(subnav_generator)
        end
      end
    end
  end
end
