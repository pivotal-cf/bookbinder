class Cli
  class Tag < BookbinderCommand
    def run(params)
      tag = params.pop
      name = `grep url .git/config`.match(/([\w-]+\/[\w-]+)\.git/)[1]
      book = Book.new full_name: name, constituent_params: config.fetch('repos')

      book.tag_with tag
      book.tag_constituents_with tag

      log 'Success!'.green
      log " #{book.full_name.yellow} at #{book.sha[0..7]} and its document repositories were tagged with #{tag.blue}"

      0
    end
  end
end