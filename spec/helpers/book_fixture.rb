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
      topics(dita_section).map { |topic| html_filename_for topic }
    end

    def has_applied_layout(dita_section)
      topics(dita_section).all? { |topic| has_applied_layout? topic }
    end

    def uses_dita_filtered_values(dita_section, included_text, excluded_text)
      topics(dita_section).all? { |topic| contains_text? topic, included_text } &&
      topics(dita_section).all? { |topic| !contains_text? topic, excluded_text }
    end

    def has_frontmatter(dita_section)
      topics(dita_section).all? { |topic| has_frontmatter? topic }
    end

    def final_images_for(dita_section)
      final_dirname = dita_section.dir || dita_section.repo_name
      dirpath = Pathname("./final_app/public/#{final_dirname}")

      png_images = Dir.glob(File.join dirpath, "**/*.png")
      jpeg_images = Dir.glob(File.join dirpath, "**/*.jpeg")
      png_images + jpeg_images
    end

    def has_dita_subnav(dita_section)
      topics(dita_section).all? { |topic| has_dita_subnav? topic }
    end

    def exposes_subnav_links_for(dita_section)
      topic_html = File.read(topics(dita_section).first.final_path)
      doc = Nokogiri::HTML(topic_html)

      doc.css('.nav-content li:nth-child(1) a').first['href'] == "/#{dita_section.dir}/some-guide.html"
    end

    def invokes_dita_option_for_css_path(dita_section, options)
      flags = dita_flags_from(options)
      copied_css_file_location = Pathname("./output/preprocessing/html_from_preprocessing/#{dita_section.dir}/" +
                                          flags['args.csspath'] +
                                          flags['args.css'])
      File.exist? copied_css_file_location
    end

    private

    def topics(dita_section)
      repo_name = dita_section.repo_name
      dir = dita_section.dir

      if section_source == SectionSource.local
        section_location = Pathname("../#{repo_name}")
      else
        section_location = Pathname("./output/preprocessing/sections/#{dir}")
      end

      path_to_ditamap = Pathname("#{section_location}/example.ditamap")
      dita_doc = Nokogiri::XML(path_to_ditamap)
      dita_doc.xpath('//topicref').map do |topic|
        topicname = topic.attr('href').split('.xml').first

        Topic.new(Pathname("./final_app/public/#{dir}/#{topicname}.html"),
                  Pathname("./output/preprocessing/site_generator_ready/#{dir}/#{topicname}.html.erb"),
                  Pathname("#{section_location}/#{topicname}.xml"),
                  topicname)
      end
    end

    def html_filename_for(topic)
      frag = Nokogiri::HTML.fragment(topic.final_path.read)
      topic.name if frag.css("div.body.conbody").present?
    end

    def has_applied_layout?(topic)
      text = File.read topic.final_path
      text.include? "<title>'This was from a layout'</title>"
    end

    def has_dita_subnav?(topic)
      doc = Nokogiri::HTML(File.read(topic.final_path))

      doc.css('.nav-content ul li').length > 0
    end

    def has_frontmatter?(topic)
      final_text = File.read topic.site_generator_ready_path
      doc = Nokogiri::XML(File.read topic.raw_dita_path)
      topicname = doc.xpath('//title').first.inner_html
      sanitized_topicname = topicname.gsub('"', '\"')

      final_text.include? "---\ntitle: \"#{sanitized_topicname}\"\ndita: true\n---\n"
    end

    def contains_text?(topic, text)
      File.read(topic.final_path).include?(text)
    end

    def dita_flags_from(dita_options)
      opts = dita_options.split(' ')

      opts.inject({}) do |res, o|
        flag, val = o.split('=')
        res[flag] = val.gsub(/['|"]/, '')
        res
      end
    end
  end

  Topic = Struct.new(:final_path, :site_generator_ready_path, :raw_dita_path, :name)
  SectionSource = OpenStruct.new(local: 0, remote: 1)

end
