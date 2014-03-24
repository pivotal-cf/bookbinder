class Book
  attr_reader :sections

  def self.from_remote(full_name: nil, destination_dir: nil, ref: nil)
    book = new(full_name: full_name, target_ref: ref)
    book.copy_from_remote(destination_dir) if destination_dir
    book
  end

  def initialize(full_name: nil, target_ref: nil, github_token: nil, sections: [])
    @sections = sections.map do |section|
      Repository.new full_name: section['repository']['name']
    end

    @repository = Repository.new(full_name: full_name, target_ref: target_ref, github_token: github_token)
  end

  def full_name
    @repository.full_name
  end

  def head_sha
    @repository.head_sha
  end

  def copy_from_remote(destination_dir)
    @repository.copy_from_remote(destination_dir)
  end

  def directory
    @repository.directory
  end

  def tag_self_and_sections_with(tag)
    (@sections + [@repository]).each { |repo| repo.tag_with tag }
  end
end
