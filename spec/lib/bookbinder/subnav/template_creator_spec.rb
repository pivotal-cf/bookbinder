require_relative '../../../../lib/bookbinder/html_document_manipulator'
require_relative '../../../../lib/bookbinder/local_filesystem_accessor'
require_relative '../../../../lib/bookbinder/subnav/template_creator'
require_relative '../../../../lib/bookbinder/values/output_locations'
require_relative '../../../../lib/bookbinder/config/subnav_config'

module Bookbinder
  module Subnav
    describe TemplateCreator do
      it 'writes the template to subnavs directory' do
        output_locations = OutputLocations.new(context_dir: '.')
        subnav_config = Config::SubnavConfig.new({'name' => 'best'})
        props_filename = 'props.json'
        template_content = 'our template'
        generated_content = 'generated template'

        fs = instance_double('Bookbinder::LocalFilesystemAccessor')
        html_doc_manipulator = instance_double('Bookbinder::HtmlDocumentManipulator')

        subnavs_dir = output_locations.subnavs_for_layout_dir

        expect(fs).to receive(:read).with(subnavs_dir.join('subnav_template.erb')) { template_content }.ordered
        expect(html_doc_manipulator).to receive(:set_attribute).with(document: template_content,
                                                                     selector: 'div.nav-content',
                                                                     attribute: 'data-props-location',
                                                                     value: props_filename) { generated_content}.ordered

        expect(fs).to receive(:write).with(text: generated_content, to: subnavs_dir.join('best.erb')).ordered

        TemplateCreator.new(fs, output_locations, html_doc_manipulator).create(props_filename, subnav_config)
      end
    end
  end
end
