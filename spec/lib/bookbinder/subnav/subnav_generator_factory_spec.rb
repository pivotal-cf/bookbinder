require_relative '../../../../lib/bookbinder/subnav/subnav_generator'
require_relative '../../../../lib/bookbinder/subnav/subnav_generator_factory'
require_relative '../../../../lib/bookbinder/subnav/template_creator'
require_relative '../../../../lib/bookbinder/subnav/pdf_config_creator'
require_relative '../../../../lib/bookbinder/values/output_locations'
require_relative '../../../../lib/bookbinder/html_document_manipulator'

module Bookbinder
  module Subnav
    describe SubnavGeneratorFactory do
      describe 'produce' do
        it 'returns a subnav generator' do
          json_generator = double('json generator')
          fs = double('local filesystem accessor')
          template_creator = double('template creator')
          subnav_generator = double('subnav generator')
          pdf_config_creator = double('pdf config creator')

          html_manipulator = double('html manipulator')
          allow(HtmlDocumentManipulator).to receive(:new) { html_manipulator }

          output_locations = OutputLocations.new(context_dir: '.')
          factory = SubnavGeneratorFactory.new(fs, output_locations)

          allow(TemplateCreator).to receive(:new).with(fs, output_locations) { template_creator }
          allow(PdfConfigCreator).to receive(:new).with(fs, output_locations) { pdf_config_creator }

          expect(SubnavGenerator).to receive(:new).with(json_generator, template_creator, pdf_config_creator, output_locations) { subnav_generator }
          expect(factory.produce(json_generator)).to be(subnav_generator)
        end
      end
    end
  end
end
