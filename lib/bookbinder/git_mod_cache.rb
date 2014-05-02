require 'yaml'

class GitModCache
  def initialize(storage)
    @storage = storage
  end

  def update_from(repo)
    current_contents = contents_on_disk

    new_contents = YAML.dump new_contents(current_contents, repo)

    f = File.open(@storage, 'w')
    f.write(new_contents)
    f.close
  end

  def fetch(path)
    sha = contents_on_disk.fetch(:shas_by_file, {})[path]
    contents_on_disk.fetch(:dates_by_sha, {})[sha]
  end

  private

  def contents_on_disk
    load_storage || {}
  end

  def load_storage
    YAML.load_file(@storage) if File.exists?(@storage)
  end

  def new_contents(current_contents, repo)
    cached_dates_by_sha = current_contents.fetch(:dates_by_sha, {})
    cached_shas_by_file = current_contents.fetch(:shas_by_file, {})
    latest_shas_by_file = repo.shas_by_file

    shas_by_file = {}
    cached_shas_by_file.merge(latest_shas_by_file).each do |k, v|
      k2 = k.gsub(/(md|html\.md\.erb|md\.erb|html\.md)$/, 'html')
      shas_by_file[k2] = v
    end

    {
        shas_by_file: shas_by_file,
        dates_by_sha: cached_dates_by_sha.merge(repo.dates_by_sha(latest_shas_by_file, except: cached_dates_by_sha))
    }
  end
end
