require_relative '../../../lib/bookbinder/values/user_message'
require_relative '../../../lib/bookbinder/colorizer'
require_relative '../../../lib/bookbinder/terminal'

module Bookbinder
  module Subnav
    class TemplateCreator
      def initialize(fs, output_locations, html_doc_manipulator)
        @fs = fs
        @output_locations = output_locations
        @html_doc_manipulator = html_doc_manipulator
      end

      def create(props_filename, subnav_spec)
        template_content = fs.read(template_path)
        nav_with_props = html_doc_manipulator.set_attribute(document: template_content,
                                                            selector: 'div.nav-content',
                                                            attribute: 'data-props-location',
                                                            value: props_filename)

        nav_content = html_doc_manipulator.add_class(document: nav_with_props,
                                                         selector: 'div.nav-content',
                                                         classname: nav_type(subnav_spec))

        fs.write(text: nav_content, to: subnav_destination(subnav_spec.subnav_name))
      end

      attr_reader :fs, :output_locations, :html_doc_manipulator

      private

      def nav_type(subnav_spec)
        subnav_spec.subnav_name.include?('dita') ? 'deepnav-content' : 'shallownav-content'
      end

      def subnavs_path
        output_locations.subnavs_for_layout_dir
      end

      def filename(name)
        "#{name}.erb"
      end

      def template_path
        deprecated_prefix = '_dita_' unless fs.file_exist?(subnavs_path.join('subnav_template.erb'))

        if deprecated_prefix
          Terminal.new(Colorizer.new).update(UserMessage.new(
            "Use of '_dita_subnav_template.erb' is deprecated. " +
              "The preferred template is 'subnav_template.erb'. Please rename your file.",
            EscalationType.warn
          ))
        end
        subnavs_path.join("#{deprecated_prefix}subnav_template.erb")
      end

      def subnav_destination(name)
        subnavs_path.join(filename(name))
      end
    end
  end
end
