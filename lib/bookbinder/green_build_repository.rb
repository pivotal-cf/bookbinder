class GreenBuildRepository

  include BookbinderLogger

  def initialize(aws_key, aws_secret_key)
    @aws_key = aws_key
    @aws_secret_key = aws_secret_key
  end

  def create(build_number, app_dir, bucket)
    directory = connection.directories.create key: bucket

    tmp_dir = Dir.mktmpdir
    tarball = File.join(tmp_dir, "#{build_number}.tgz")

    Dir.chdir app_dir do
      `tar czf #{tarball} *`
    end

    directory.files.create :key => "#{build_number}.tgz",
                           :body => File.read(tarball),
                           :public => true

    tarball
  end

  def download(empty_app_dir, bucket, build_number = nil)
    directory = connection.directories.get bucket

    build_number_to_download = build_number || highest_build_number(directory)
    filename = "#{build_number_to_download}.tgz"
    s3_file = directory.files.get(filename)

    tmpdir = Dir.mktmpdir
    downloaded_file = File.join(tmpdir, 'downloaded.tgz')
    File.open(downloaded_file, 'w') { |f| f.write(s3_file.body) }

    Dir.chdir empty_app_dir do
      `tar xzf #{downloaded_file}`
    end

    log 'Green build ' + "##{build_number_to_download}".green +
        " has been downloaded from S3 and untarred into #{empty_app_dir.cyan}"
  end

  private

  def highest_build_number(directory)
    build_numbers = directory.files.map(&:key).map do |key|
      matches = /^([\d]+)\.tgz/.match(key)
      matches && matches[1]
    end.map(&:to_i).sort
    build_numbers[build_numbers.size - 1]
  end

  def connection
    @connection ||= Fog::Storage.new :provider => 'AWS',
                                     :aws_access_key_id => @aws_key,
                                     :aws_secret_access_key => @aws_secret_key
  end
end