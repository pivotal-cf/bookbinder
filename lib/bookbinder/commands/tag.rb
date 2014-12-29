module Bookbinder
  class Cli
    class Tag < BookbinderCommand
      def self.usage
        'tag <git tag>'
      end

      def run(params)
        tag = params.first
        raise Cli::InvalidArguments unless tag

        book = Book.new(logger: @logger, full_name: config.book_repo, sections: config.sections)

        book.tag_self_and_sections_with tag

        @logger.log 'Success!'.green
        @logger.log " #{book.full_name.yellow} and its sections were tagged with #{tag.blue}"
        0
      end
    end
  end
end
