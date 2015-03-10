require 'nokogiri'
require 'ostruct'

module Bookbinder
  class BookFixture
    attr_reader :name, :section_source

    def initialize(book_name, section_source)
      @name = book_name
      @section_source = section_source
    end

    def html_files_for_dita_section(dita_section)
      topics(dita_section).map { |topic| has_html_file_for? topic }
    end

    def has_applied_layout(dita_section)
      topics(dita_section).all? { |topic| has_applied_layout? topic }
    end

    def has_frontmatter(dita_section)
      topics(dita_section).all? { |topic| has_frontmatter? topic }
    end

    def final_images_for(dita_section)
      final_images_path = Pathname("./final_app/public/#{dita_section}/images")
      Dir.glob(File.join final_images_path, "**/*")
    end

    def has_dita_subnav(dita_section)
      topics(dita_section).all? { |topic| has_dita_subnav? topic }
    end

    def exposes_subnav_links_for_js(dita_section)
      text = File.read("./output/master_middleman/source/subnavs/#{dita_section}_subnav.erb")
      doc = Nokogiri::XML(text)
      props = doc.css('.nav-content').first.attr('data-props-location')

      !File.zero?("./output/master_middleman/source/subnavs/#{dita_section}-props.json") &&
          (props == "#{dita_section}-props.json")
    end

    private

    def topics(dita_section)
      if section_source == SectionSource.local
        section_location = Pathname("../#{dita_section}")
      else
        section_location = Pathname("./output/dita/dita_sections/#{dita_section}")
      end

      path_to_ditamap = Pathname("#{section_location}/example.ditamap")
      dita_doc = Nokogiri::XML(path_to_ditamap)
      dita_doc.xpath('//topicref').map do |topic|
      topicname = topic.attr('href').split('.xml').first

      Topic.new(Pathname("./final_app/public/#{dita_section}/#{topicname}.html"),
                Pathname("./output/dita/site_generator_ready/#{dita_section}/#{topicname}.html.erb"),
                Pathname("#{section_location}/#{topicname}.xml"),
                topicname)
      end
    end

    def has_html_file_for?(topic)
      frag = Nokogiri::HTML.fragment(topic.final_path.read)
      topic.name if frag.css("div.body.conbody").present?
    end

    def has_applied_layout?(topic)
      text = File.read topic.final_path
      text.include? "<title>'This was from a layout'</title>"
    end

    def has_dita_subnav?(topic)
      text = File.read topic.final_path
      doc = Nokogiri::HTML(text)

      text.include?('<div class="nav-content"') &&
          doc.css('.nav-content').first.attr('data-props-location').present?
    end

    def has_frontmatter?(topic)
      final_text = File.read topic.site_generator_ready_path
      doc = Nokogiri::XML(File.read topic.raw_dita_path)
      topicname = doc.xpath('//title').first.inner_html
      sanitized_topicname = topicname.gsub('"', '\"')

      final_text.include? "---\ntitle: \"#{sanitized_topicname}\"\ndita: true\n---\n"
    end

  end

  Topic = Struct.new(:final_path, :site_generator_ready_path, :raw_dita_path, :name)
  SectionSource = OpenStruct.new(local: 0, remote: 1)

end
