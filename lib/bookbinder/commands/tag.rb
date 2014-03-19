class Cli
  class Tag < BookbinderCommand
    def run(params)
      tag = params.first
      book = Book.new(full_name: config.book_repo, constituent_params: config.repos)

      book.tag_self_and_constituents_with tag

      log 'Success!'.green
      log " #{book.full_name.yellow} its document repositories were tagged with #{tag.blue}"
      0
    end

    def self.usage
      '<git tag>'
    end
  end
end
