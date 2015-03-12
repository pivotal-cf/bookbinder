module Bookbinder
  module Config
    class LocalBindConfiguration
      def initialize(base_config)
        @base_config = base_config
      end

      def to_h
        {
          sections: base_config.sections,
          book_repo: base_config.book_repo,
          host_for_sitemap: base_config.public_host,
          archive_menu: base_config.archive_menu,
          template_variables: base_config.template_variables
        }
      end

      private

      attr_reader :base_config
    end
  end
end
