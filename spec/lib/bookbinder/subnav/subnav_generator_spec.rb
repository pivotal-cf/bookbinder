require_relative '../../../../lib/bookbinder/subnav/subnav_generator'
require_relative '../../../../lib/bookbinder/subnav/navigation_entries_from_html_toc'
require_relative '../../../../lib/bookbinder/subnav/template_creator'
require_relative '../../../../lib/bookbinder/subnav/pdf_config_creator'
require_relative '../../../../lib/bookbinder/config/product_config'

module Bookbinder
  module Subnav
    describe SubnavGenerator do
      let(:output_locations) { 'locations!' }
      context 'without pdf_config in config' do
        it 'creates a json props file and then creates the template and pdf configs' do
          product_config = Config::ProductConfig.new({})
          navigation_entries = 'entries and stuff'

          navigation_entries_parser = instance_double(Bookbinder::Subnav::NavigationEntriesFromHtmlToc)
          template_creator = instance_double(Bookbinder::Subnav::TemplateCreator)
          pdf_config_creator = instance_double(Bookbinder::Subnav::PdfConfigCreator)

          expect(navigation_entries_parser).to receive(:get_links).with(product_config, output_locations) { navigation_entries }
          expect(template_creator).to receive(:create).with(navigation_entries, product_config)

          SubnavGenerator.new(navigation_entries_parser, template_creator, pdf_config_creator, output_locations)
            .generate(product_config)
        end
      end

      context 'with pdf_config in config' do
        it 'creates a json props file and then creates the template and pdf configs' do
          product_config = Config::ProductConfig.new({'whatever' => 'thing', 'pdf_config' => 'blah'})
          navigation_entries = 'entries and stuff'

          navigation_entries_parser = instance_double(Bookbinder::Subnav::NavigationEntriesFromHtmlToc)
          template_creator = instance_double(Bookbinder::Subnav::TemplateCreator)
          pdf_config_creator = instance_double(Bookbinder::Subnav::PdfConfigCreator)

          expect(navigation_entries_parser).to receive(:get_links).with(product_config, output_locations) { navigation_entries }
          expect(template_creator).to receive(:create).with(navigation_entries, product_config)
          expect(pdf_config_creator).to receive(:create).with(navigation_entries, product_config)

          SubnavGenerator.new(navigation_entries_parser, template_creator, pdf_config_creator, output_locations)
            .generate(product_config)
        end
      end

      it 'does not error when trying to access a pdf config when method not implemented' do
        expect {
          SubnavGenerator.new(
            double('props creator').as_null_object,
            double('template_creator').as_null_object,
            double('pdf_config_creator').as_null_object,
            output_locations).generate({})
        }.to_not raise_error
      end
    end
  end
end
