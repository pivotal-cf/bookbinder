module Bookbinder

  Section = Struct.new(:path_to_repository,
                       :full_name,
                       :copied,
                       :subnav_templ,
                       :destination_dir,
                       :directory_name) do
    def path_to_repository
      Pathname(self[:path_to_repository].to_s)
    end

    def subnav_template
      subnav_templ.sub(/^_/, '').sub(/\.erb$/, '') if subnav_templ
    end

    def directory
      directory_name
    end

    def subnav
      namespace = directory.gsub('/', '_')
      template = subnav_template || 'default'
      {namespace => template}
    end
  end
end
