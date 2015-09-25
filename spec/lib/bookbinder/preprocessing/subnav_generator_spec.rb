require_relative '../../../../lib/bookbinder/preprocessing/subnav_generator'
require_relative '../../../../lib/bookbinder/preprocessing/json_props_creator'
require_relative '../../../../lib/bookbinder/preprocessing/template_creator'
require_relative '../../../../lib/bookbinder/config/subnav_config'

module Bookbinder
  module Preprocessing
    describe SubnavGenerator do
      it 'creates a json props file and passes the return to template creator' do
        subnav_config = Config::SubnavConfig.new({'whatever' => 'thing'})
        props_location = Pathname('some/dir')

        props_creator = instance_double('Bookbinder::Preprocessing::JsonPropsCreator')
        template_creator = instance_double('Bookbinder::Preprocessing::TemplateCreator')

        expect(props_creator).to receive(:create).with(subnav_config) { props_location }
        expect(template_creator).to receive(:create).with(props_location)

        SubnavGenerator.new(props_creator, template_creator)
          .generate(subnav_config)
      end
    end
  end
end
