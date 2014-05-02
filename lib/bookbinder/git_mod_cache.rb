require 'yaml'

class GitModCache
  def initialize(storage)
    @storage = storage
  end

  def update_from(repo)
    current_contents = contents_on_disk
    cached_dates_by_sha = current_contents.fetch(:dates_by_sha, {})
    cached_shas_by_file = current_contents.fetch(:shas_by_file, {})

    latest_shas_by_file = repo.shas_by_file
    pretty_latest_shas_by_file = prettify(latest_shas_by_file, repo.directory)
    new_dates_by_sha = repo.dates_by_sha(latest_shas_by_file, except: cached_dates_by_sha)

    shas_by_file = cached_shas_by_file.merge(pretty_latest_shas_by_file)
    dates_by_sha = cached_dates_by_sha.merge(new_dates_by_sha)

    new_contents = {
        shas_by_file: shas_by_file,
        dates_by_sha: dates_by_sha
    }

    new_contents_yaml = YAML.dump new_contents

    write_to_disk(new_contents_yaml)
  end

  def fetch(path)
    sha = contents_on_disk.fetch(:shas_by_file, {})[path]
    contents_on_disk.fetch(:dates_by_sha, {})[sha]
  end

  private

  def write_to_disk(new_contents_yaml)
    f = File.open(@storage, 'w')
    f.write(new_contents_yaml)
    f.close
  end

  def prettify(shas_by_file, directory)
    output_shas_by_file = {}

    shas_by_file.each do |file, sha|
      pretty_file = File.join(directory, file.gsub(/(md|html\.md\.erb|md\.erb|html\.md)$/, 'html'))
      output_shas_by_file[pretty_file] = sha
    end

    output_shas_by_file
  end

  def contents_on_disk
    load_storage || {}
  end

  def load_storage
    YAML.load_file(@storage) if File.exists?(@storage)
  end

end
