require 'spec_helper'

describe GreenBuildRepository do

  around do |example|
    Fog.mock!
    Fog::Mock.reset
    example.run
    Fog.unmock!
  end

  include_context 'tmp_dirs'

  let(:fog_connection) do
    Fog::Storage.new :provider => 'AWS',
                     :aws_access_key_id => 'aws-key',
                     :aws_secret_access_key => 'aws-secret-key'
  end
  let(:bucket_key) { 'pivotal-cf-docs-green-builds' }
  let(:green_build_repository) { GreenBuildRepository.new key: 'aws-key', secret: 'aws-secret-key' }


  describe '#create' do
    let(:build_number) { 42 }
    let(:create) { green_build_repository.create build_number: 42, app_dir: final_app_dir, bucket: bucket_key }
    let(:final_app_dir) { tmp_subdir 'final_app' }

    before do
      File.open(File.join(final_app_dir, 'stuff.txt'), 'w') { |f| f.write('this is stuff') }
    end

    shared_examples_for 'a green_build_repository' do
      it 'uploads a file with the build number in the key' do
        create
        directory = fog_connection.directories.get(bucket_key)
        expect(directory.files.get('42.tgz')).not_to be_nil
      end

      it 'uploads a tarball with the contents of the given app directory' do
        create
        s3_file = fog_connection.directories.get(bucket_key).files.get('42.tgz')

        File.open(File.join(tmpdir, 'uploaded.tgz'), 'wb') do |f|
          f.write(s3_file.body)
        end

        exploded_dir = tmp_subdir('exploded')
        `cd #{exploded_dir} && tar xzf ../uploaded.tgz`

        contents = File.read(File.join(exploded_dir, 'stuff.txt'))
        expect(contents).to eq('this is stuff')
      end
    end

    context 'when the bucket does not yet exist' do
      it 'creates the bucket' do
        create
        directory = fog_connection.directories.get(bucket_key)
        expect(directory).not_to be_nil
      end

      it_behaves_like 'a green_build_repository'
    end

    context 'when the bucket is already there' do
      before do
        fog_connection.directories.create key: bucket_key
      end
      it_behaves_like 'a green_build_repository'
    end
  end

  describe '#download' do
    let(:app_dir) { tmp_subdir 'app_dir' }
    let(:bucket) { fog_connection.directories.create key: bucket_key }
    let(:download) do
      green_build_repository.download download_dir: app_dir,
                                      bucket: bucket_key,
                                      build_number: build_number
    end

    before do
      expect(fog_connection.directories).to be_empty
    end

    context 'when not given a specific build number' do
      let(:build_number) { nil }

      context 'and there are files in the bucket that follow the naming pattern' do
        before do
          create_s3_file '17'
          create_s3_file '3'
        end

        it 'downloads the build with the highest build number' do
          download
          untarred_file = File.join(app_dir, 'stuff.txt')
          contents = File.read(untarred_file)
          expect(contents).to eq('contents of 17')
        end
      end

      context 'and when the only file in the bucket does not conform to the naming pattern' do
        before do
          create_s3_file '178foo'
        end

        it 'is blows up rather than trying to download it' do
          expect {download}.to raise_error(GreenBuildRepository::FileDoesNotExist)
        end
      end
    end

    context 'when given a specific build number and that build is in the bucket' do
      let(:build_number) { 3 }
      before do
        create_s3_file '3'
      end

      it 'downloads the build with the highest build number' do
        download
        untarred_file = File.join(app_dir, 'stuff.txt')
        contents = File.read(untarred_file)
        expect(contents).to eq('contents of 3')
      end
    end

    context 'when given a specific build number and that build does not exist in the bucket' do
      let(:build_number) { 99 }

      before do
        bucket
      end

      it 'prints an error message and returns nil' do
        expect{ download }.to raise_error(GreenBuildRepository::FileDoesNotExist)
      end
    end

    def tarball_with_contents(contents)
      directory_to_tar = Dir.mktmpdir
      Dir.chdir directory_to_tar do
        File.open('stuff.txt', 'w') { |f| f.write(contents) }
        tarball_file = File.join(Dir.mktmpdir, 'tarball.tgz')
        `tar czf #{tarball_file} *`
        File.read(tarball_file)
      end
    end

    def create_s3_file(name)
      bucket.files.create :key => "#{name}.tgz",
                          :body => tarball_with_contents("contents of #{name}"),
                          :public => true
    end

  end
end