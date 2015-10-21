require_relative '../../../../lib/bookbinder/html_document_manipulator'
require_relative '../../../../lib/bookbinder/local_filesystem_accessor'
require_relative '../../../../lib/bookbinder/subnav/template_creator'
require_relative '../../../../lib/bookbinder/values/output_locations'
require_relative '../../../../lib/bookbinder/values/section'
require_relative '../../../../lib/bookbinder/config/subnav_config'
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
        subnav_config = Config::SubnavConfig.new({'name' => 'best'})
        props_filename = 'props.json'

        allow(fs).to receive(:file_exist?) { true }

        expect(fs).to receive(:read).with(subnavs_dir.join('subnav_template.erb')) { template_content }
        expect(html_doc_manipulator).to receive(:set_attribute)
        expect(html_doc_manipulator).to receive(:add_class) { manipulated_content }

        expect(fs).to receive(:write).with(text: manipulated_content, to: subnavs_dir.join('best.erb'))

        TemplateCreator.new(fs, output_locations, html_doc_manipulator).create(props_filename, subnav_config)
      end

      context 'for dita subnav' do
        it 'sets class "deepnav" on the nav content div' do
          section = Section.new(nil, nil, nil, 'dita_nav')

          allow(fs).to receive(:file_exist?).with(subnavs_dir.join('subnav_template.erb')) { true }
          allow(fs).to receive(:write)

          expect(fs).to receive(:read).with(subnavs_dir.join('subnav_template.erb')) { template_content }
          expect(html_doc_manipulator).to receive(:set_attribute).with(document: template_content,
                                                                       selector: 'div.nav-content',
                                                                       attribute: 'data-props-location',
                                                                       value: 'props.json') { manipulated_content }

          expect(html_doc_manipulator).to receive(:add_class).with(document: manipulated_content,
                                                                   selector: 'div.nav-content',
                                                                   classname: 'deepnav-content')

          TemplateCreator.new(fs, output_locations, html_doc_manipulator).create('props.json', section)
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

          expect(html_doc_manipulator).to receive(:add_class).with(document: manipulated_content,
                                                                   selector: 'div.nav-content',
                                                                   classname: 'deepnav-content')

          TemplateCreator.new(fs, output_locations, html_doc_manipulator).create('props.json', section)
        end
      end

      context 'for regular subnav' do
        it 'sets class "shallownav" on the nav content div' do
          config = Config::SubnavConfig.new({'name' => 'some_nav_name'})

          allow(fs).to receive(:file_exist?) { true }
          allow(fs).to receive(:write)

          expect(fs).to receive(:read).with(subnavs_dir.join('subnav_template.erb')) { template_content }
          expect(html_doc_manipulator).to receive(:set_attribute).with(document: template_content,
              selector: 'div.nav-content',
              attribute: 'data-props-location',
              value: 'props.json') { manipulated_content }

          expect(html_doc_manipulator).to receive(:add_class).with(document: manipulated_content,
                                                                   selector: 'div.nav-content',
                                                                   classname: 'shallownav-content')

          TemplateCreator.new(fs, output_locations, html_doc_manipulator).create('props.json', config)
        end
      end
    end
  end
end
