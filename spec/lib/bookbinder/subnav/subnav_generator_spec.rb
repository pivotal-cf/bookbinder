require_relative '../../../../lib/bookbinder/subnav/subnav_generator'
require_relative '../../../../lib/bookbinder/subnav/json_props_creator'
require_relative '../../../../lib/bookbinder/subnav/template_creator'
require_relative '../../../../lib/bookbinder/subnav/pdf_config_creator'
require_relative '../../../../lib/bookbinder/config/subnav_config'

module Bookbinder
  module Subnav
    describe SubnavGenerator do
      context 'without pdf_config in config' do
        it 'creates a json props file and then creates the template and pdf configs' do
          subnav_config = Config::SubnavConfig.new({})
          props_filename = 'props.json'

          props_creator = instance_double('Bookbinder::Preprocessing::JsonPropsCreator')
          template_creator = instance_double('Bookbinder::Preprocessing::TemplateCreator')
          pdf_config_creator = instance_double('Bookbinder::Preprocessing::PdfConfigCreator')

          expect(props_creator).to receive(:create).with(subnav_config) { props_filename }
          expect(template_creator).to receive(:create).with(props_filename, subnav_config)

          SubnavGenerator.new(props_creator, template_creator, pdf_config_creator)
            .generate(subnav_config)
        end
      end

      context 'with pdf_config in config' do
        it 'creates a json props file and then creates the template and pdf configs' do
          subnav_config = Config::SubnavConfig.new({'whatever' => 'thing', 'pdf_config' => 'blah'})
          props_filename = 'props.json'

          props_creator = instance_double('Bookbinder::Preprocessing::JsonPropsCreator')
          template_creator = instance_double('Bookbinder::Preprocessing::TemplateCreator')
          pdf_config_creator = instance_double('Bookbinder::Preprocessing::PdfConfigCreator')

          expect(props_creator).to receive(:create).with(subnav_config) { props_filename }
          expect(template_creator).to receive(:create).with(props_filename, subnav_config)
          expect(pdf_config_creator).to receive(:create).with(props_filename, subnav_config)

          SubnavGenerator.new(props_creator, template_creator, pdf_config_creator)
            .generate(subnav_config)
        end
      end
    end
  end
end
