require_relative '../../../../lib/bookbinder/subnav/subnav_generator'
require_relative '../../../../lib/bookbinder/subnav/json_props_creator'
require_relative '../../../../lib/bookbinder/subnav/template_creator'
require_relative '../../../../lib/bookbinder/subnav/pdf_config_creator'
require_relative '../../../../lib/bookbinder/config/product_config'

module Bookbinder
  module Subnav
    describe SubnavGenerator do
      context 'without pdf_config in config' do
        it 'creates a json props file and then creates the template and pdf configs' do
          product_config = Config::ProductConfig.new({})
          props_filename = 'props.json'

          props_creator = instance_double(Bookbinder::Subnav::JsonPropsCreator)
          template_creator = instance_double(Bookbinder::Subnav::TemplateCreator)
          pdf_config_creator = instance_double(Bookbinder::Subnav::PdfConfigCreator)

          expect(props_creator).to receive(:create).with(product_config) { props_filename }
          expect(template_creator).to receive(:create).with(props_filename, product_config)

          SubnavGenerator.new(props_creator, template_creator, pdf_config_creator)
            .generate(product_config)
        end
      end

      context 'with pdf_config in config' do
        it 'creates a json props file and then creates the template and pdf configs' do
          product_config = Config::ProductConfig.new({'whatever' => 'thing', 'pdf_config' => 'blah'})
          props_filename = 'props.json'

          props_creator = instance_double(Bookbinder::Subnav::JsonPropsCreator)
          template_creator = instance_double(Bookbinder::Subnav::TemplateCreator)
          pdf_config_creator = instance_double(Bookbinder::Subnav::PdfConfigCreator)

          expect(props_creator).to receive(:create).with(product_config) { props_filename }
          expect(template_creator).to receive(:create).with(props_filename, product_config)
          expect(pdf_config_creator).to receive(:create).with(props_filename, product_config)

          SubnavGenerator.new(props_creator, template_creator, pdf_config_creator)
            .generate(product_config)
        end
      end

      it 'does not error when trying to access a pdf config when method not implemented' do
        expect {
          SubnavGenerator.new(
            double('props creator').as_null_object,
            double('template_creator').as_null_object,
            double('pdf_config_creator').as_null_object).generate({})
        }.to_not raise_error
      end
    end
  end
end
