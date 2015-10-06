module Bookbinder
  module Config
    class TopicConfig
      def initialize(config)
        @config = config
      end

      def title
        config['title']
      end

      def toc_file
        config['toc_file']
      end

      def toc_nav_name
        config['toc_nav_name'] || title
      end

      def valid?
        (CONFIG_REQUIRED_KEYS - config.keys).empty?
      end

      def toc_dir_path
        Pathname(toc_file.split('/').tap{|paths| paths.pop }.join('/'))
      end

      def toc_filename
        toc_file.split('/').pop.split('.').shift
      end

      CONFIG_REQUIRED_KEYS = %w(title toc_file)

      attr_reader :config
    end
  end
end
