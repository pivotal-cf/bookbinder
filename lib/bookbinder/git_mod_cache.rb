require 'yaml'

class GitModCache
  def initialize(storage_file_path, safe_mode=false)
    @storage = storage_file_path
    @safe_mode = safe_mode
  end

  def update_from(repo)
    return if safe_mode

    cached_dates_by_sha         = contents_on_disk.fetch(:dates_by_sha, {})
    cached_shas_by_file         = contents_on_disk.fetch(:shas_by_file, {})

    latest_shas_by_file         = repo.shas_by_file
    pretty_latest_shas_by_file  = prettify(latest_shas_by_file, repo.directory)
    new_dates_by_sha            = repo.dates_by_sha(latest_shas_by_file, except: cached_dates_by_sha)

    new_contents = {
        dates_by_sha: cached_dates_by_sha.merge(new_dates_by_sha),
        shas_by_file: cached_shas_by_file.merge(pretty_latest_shas_by_file),
    }

    write_to_disk(YAML.dump new_contents)
  end

  def fetch(path)
    return Time.now.utc if safe_mode
    sha = contents_on_disk.fetch(:shas_by_file, {})[path]
    contents_on_disk.fetch(:dates_by_sha, {}).fetch(sha, Time.now.utc)
  end

  private

  attr_reader :safe_mode

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
    @contents ||= load_storage
  end

  def load_storage
    File.exists?(@storage) ? YAML.load_file(@storage) : {}
  end

end
