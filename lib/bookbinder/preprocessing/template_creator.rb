module Bookbinder
  module Preprocessing
    class TemplateCreator
      def initialize(fs, output_locations, html_doc_manipulator)
        @fs = fs
        @output_locations = output_locations
        @html_doc_manipulator = html_doc_manipulator
      end

      def create(props_filename, subnav_config)
        template_content = fs.read(template_path)
        nav_content = html_doc_manipulator.set_attribute(document: template_content,
                                                         selector: 'div.nav-content',
                                                         attribute: 'data-props-location',
                                                         value: props_filename)

        fs.write(text: nav_content, to: subnav_destination(subnav_config.name))
      end

      attr_reader :fs, :output_locations, :html_doc_manipulator

      private

      def subnavs_path
        output_locations.subnavs_for_layout_dir
      end

      def filename(name)
        "#{name}.erb"
      end

      def template_path
        subnavs_path.join('subnav_template.erb')
      end

      def subnav_destination(name)
        subnavs_path.join(filename(name))
      end
    end
  end
end
