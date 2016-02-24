require_relative '../../../../lib/bookbinder/html_document_manipulator'
require_relative '../../../../lib/bookbinder/local_filesystem_accessor'
require_relative '../../../../lib/bookbinder/subnav/template_creator'
require_relative '../../../../lib/bookbinder/values/output_locations'
require_relative '../../../../lib/bookbinder/values/section'
require_relative '../../../../lib/bookbinder/config/product_config'
require_relative '../../../../lib/bookbinder/terminal'

module Bookbinder
  module Subnav
    describe TemplateCreator do
      let(:template_content) { 'our content' }
      let(:output_locations) { OutputLocations.new(context_dir: '.') }
      let(:subnavs_dir) { output_locations.subnavs_for_layout_dir }
      let(:manipulated_content) { 'manipulated template content'}
      let(:fs) { instance_double('Bookbinder::LocalFilesystemAccessor') }
      let(:html_doc_manipulator) { instance_double('Bookbinder::HtmlDocumentManipulator') }

      it 'writes the template to subnavs directory' do
        subnav_config = Config::ProductConfig.new({'id' => 'best'})
        props_filename = 'props.json'

        allow(fs).to receive(:file_exist?) { true }

        expect(fs).to receive(:read).with(subnavs_dir.join('subnav_template.erb')) { template_content }
        expect(html_doc_manipulator).to receive(:set_attribute).
            with(hash_including(document: template_content)) { manipulated_content }

        expect(fs).to receive(:write).with(text: manipulated_content, to: subnavs_dir.join('best.erb'))

        TemplateCreator.new(fs, output_locations, html_doc_manipulator).create(props_filename, subnav_config)
      end


      it 'uses _dita_subnav_template.erb if subnav_template.erb is missing' do
        section = Section.new(nil, nil, nil, 'dita_nav')

        allow(fs).to receive(:file_exist?).with(subnavs_dir.join('subnav_template.erb')) { false }
        allow(fs).to receive(:write)

        allow_any_instance_of(Terminal).to receive(:update)

        expect(fs).to receive(:read).with(subnavs_dir.join('_dita_subnav_template.erb')) { template_content }

        expect(html_doc_manipulator).to receive(:set_attribute).with(document: template_content,
                                                                     selector: 'div.nav-content',
                                                                     attribute: 'data-props-location',
                                                                     value: 'props.json') { manipulated_content }

        TemplateCreator.new(fs, output_locations, html_doc_manipulator).create('props.json', section)
      end

    end
  end
end
