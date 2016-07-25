require 'nokogiri'

module Bookbinder 
  class Proof < ::Middleman::Extension
    def initialize(*args)
      super
      @blacklist = [
        %r{\Alayouts/},
        %r{\Asubnavs/}
      ]
    end

    def before_build(builder)
      return unless proofing?
      builder.instance_variable_set(:@parallel, false)
      @partials = Hash.new { |h, k| h[k] = [] }
      @pages = Hash.new { |h, k| h[k] = [] }
    end

    def after_build(builder)
      return unless proofing?
      @partials.values.each(&:uniq!)
      @pages.values.each(&:uniq!)

      @pages.each do |page_path, partials|
        full_path = File.join(app.config.build_dir, page_path)
        page = File.open(full_path) {|file| Nokogiri::HTML file}

        page.css('.partial-notice').each do |node|
          if node.text =~ /\ABEGIN PARTIAL (.+)\. Partial appears in these topics:\z/
            partial_name = $1
            all_files_using_partial = @partials[partial_name]

            list = page.create_element('ul')
            all_files_using_partial.each do |file_name|
              li = list.add_child(page.create_element('li'))
              link = li.add_child(page.create_element('a', file_name, href: "/#{file_name}"))
            end

            node.add_child(list)
          end
        end

        File.open(full_path, 'w') { |file| file.puts page.to_html }
      end
    end

    expose_to_template :proofing?
    expose_to_template :track_partial

    helpers do
      def partial(template, *args)
        contents = [super]

        if proofing?
          dir, name = File.split(template)
          partial_template = File.join(dir, "_#{name}")
          template_obj = locate_partial(partial_template, false) || locate_partial(partial_template, true)
          template_path = template_obj.relative_path.to_s

          if track_partial(template_path, current_resource.path)
            contents.unshift %Q{<div class="partial-notice">BEGIN PARTIAL #{template_path}. Partial appears in these topics:</div>}
            contents.push %Q{<div class="partial-notice">END PARTIAL #{template_path}</div>}
          end
        end

        contents.join('')
      end
    end

    def track_partial(template, page)
      result = !blacklisted?(template)
      if result
        @partials[template] << page
        @pages[page] << template
      end
      result
    end

    def proofing?
      !!app.config[:proof]
    end

    def blacklisted?(template)
      @blacklist.any? { |matcher| matcher.match template }
    end
  end
end

::Middleman::Extensions.register(:proof, Bookbinder::Proof)
