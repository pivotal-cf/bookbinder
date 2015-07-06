require_relative '../../../../lib/bookbinder/deploy/archive'
require_relative '../../../helpers/nil_logger'
require_relative '../../../helpers/tmp_dirs'

module Bookbinder
  module Deploy
    describe Archive do
      unless ENV['REAL_S3']
        around do |example|
          Fog.mock!
          Fog::Mock.reset
          example.run
          Fog.unmock!
        end
      end

      include_context 'tmp_dirs'

      let(:aws_access_key_id) { ENV.fetch('AWS_ACCESS_KEY_ID', '') }
      let(:aws_secret_access_key) { ENV.fetch('AWS_SECRET_ACCESS_KEY', '') }

      let(:fog_connection) do
        Fog::Storage.new(provider: 'AWS',
                         aws_access_key_id: aws_access_key_id,
                         aws_secret_access_key: aws_secret_access_key,
                         region: 'us-east-1')
      end
      let(:bucket_key) { "pivotal-cf-docs-green-builds-#{SecureRandom.hex}" }
      let(:logger) { NilLogger.new }
      let(:archive) { Archive.new(logger: logger,
                                  key: aws_access_key_id,
                                  secret: aws_secret_access_key) }

      def delete
        bucket = fog_connection.directories.get(bucket_key)
        if bucket
          bucket.files.each(&:destroy)
          bucket.destroy
        end
      end

      after do
        delete
      end

      describe 'archiving and uploading in one step (splitting in #95544310)' do
        let(:build_number) { 42 }
        let(:namespace) { 'pcf' }
        let(:final_app_dir) { tmp_subdir 'final_app' }

        def create
          archive.create_and_upload_tarball build_number: build_number,
                                            namespace: namespace,
                                            app_dir: final_app_dir,
                                            bucket: bucket_key
        end

        before do
          File.write(final_app_dir.join('stuff.txt'), 'this is stuff')
        end

        shared_examples_for 'an archive' do
          it "is successful" do
            expect(create).to be_success
          end

          it 'uploads a file with the build number in the key' do
            create
            directory = fog_connection.directories.get(bucket_key)
            expect(directory.files.get("#{namespace}-#{build_number}.tgz")).not_to be_nil
          end

          it 'uploads a tarball with the contents of the given app directory' do
            create
            s3_file = fog_connection.directories.get(bucket_key).
              files.get("#{namespace}-#{build_number}.tgz")

            File.write(tmpdir.join('uploaded.tgz'), s3_file.body)

            exploded_dir = tmp_subdir('exploded')
            `cd #{exploded_dir} && tar xzf ../uploaded.tgz`

            contents = File.read(exploded_dir.join('stuff.txt'))
            expect(contents).to eq('this is stuff')
          end
        end

        context 'when the bucket does not yet exist' do
          it_behaves_like 'an archive'
        end

        context 'when the bucket exists' do
          before do
            fog_connection.directories.create key: bucket_key
          end

          it_behaves_like 'an archive'
        end

        context 'when the bucket is in a non-default region, and is already there' do
          before do
            eu_connection = Fog::Storage.new(provider: :aws,
                                             aws_access_key_id: aws_access_key_id,
                                             aws_secret_access_key: aws_secret_access_key,
                                             region: 'eu-west-1')
            eu_connection.directories.create(key: bucket_key)
          end

          it "creates successfully" do
            create
            directory = fog_connection.directories.get(bucket_key)
            expect(directory.files.get("#{namespace}-#{build_number}.tgz")).not_to be_nil
          end
        end
      end

      describe '#download' do
        let(:app_dir) { tmp_subdir 'app_dir' }
        let(:bucket) { fog_connection.directories.create key: bucket_key }

        def download
          archive.download download_dir: app_dir,
                           bucket: bucket_key,
                           build_number: build_number,
                           namespace: namespace
        end

        context 'when not given a specific build number' do
          let(:build_number) { nil }
          let(:namespace) { 'a-name' }

          context 'and there is more than one file in the bucket that matches the naming pattern' do
            context 'and the files all follow the build-number naming convention' do
              it 'downloads the last modified green build' do
                create_s3_file namespace, '17'

                if ENV['REAL_S3']
                  sleep 1
                else
                  allow(Time).to receive(:now).and_return(Time.now + 30)
                end

                create_s3_file namespace, '1'

                download
                untarred_file = app_dir.join('stuff.txt')
                contents = File.read(untarred_file)
                expect(contents).to eq("contents of #{namespace}-1")
              end
            end

            context 'and the files in the bucket follow both the build-number and timestamp naming conventions' do
              it 'downloads the last modified green build' do
                create_s3_file namespace, '17'
                create_s3_file namespace, '20160606_0606'
                if ENV['REAL_S3']
                  sleep 1
                else
                  allow(Time).to receive(:now).and_return(Time.now + 30)
                end
                create_s3_file namespace, '20150520_1051'

                download
                untarred_file = app_dir.join('stuff.txt')
                contents = File.read(untarred_file)
                expect(contents).to eq("contents of #{namespace}-20150520_1051")
              end
            end
          end

          context 'and there is only one file in the bucket that matches the naming pattern' do
            before do
              create_s3_file namespace, '1'
            end

            it 'downloads that file' do
              download
              untarred_file = app_dir.join('stuff.txt')
              contents = File.read(untarred_file)
              expect(contents).to eq("contents of #{namespace}-1")
            end

          end

          context 'and when there are no files that conform to the naming pattern' do
            let!(:bucket) { fog_connection.directories.create key: bucket_key }

            it 'is blows up rather than trying to download it' do
              expect {download}.to raise_error(Archive::FileDoesNotExist)
            end
          end

          context 'and when the only file in the bucket does not conform to the naming pattern' do
            before { create_s3_file namespace, '178-1.618' }

            it 'is blows up rather than trying to download it' do
              expect {download}.to raise_error(Archive::FileDoesNotExist)
            end
          end
        end

        context 'when given a specific build number and that build is in the bucket' do
          let(:build_number) { 3 }
          let(:namespace) { 'spatula' }

          before { create_s3_file namespace, build_number }

          it 'downloads the build with the given build number' do
            download
            untarred_file = app_dir.join('stuff.txt')
            contents = File.read(untarred_file)
            expect(contents).to eq('contents of spatula-3')
          end
        end

        context 'when given a specific build and that build does not exist in the bucket' do
          let(:build_number) { 99 }
          let(:namespace) { 'targaryen' }

          before { bucket }

          it 'prints an error message and returns nil' do
            expect{ download }.to raise_error(Archive::FileDoesNotExist)
          end
        end

        context 'when given an erroneous namespace' do
          let(:build_number) { 13 }
          before { create_s3_file 'a-different-namespace', build_number }

          context 'such as nil' do
            let(:namespace) { nil }
            it 'prints an error message and returns nil' do
              expect{ download }.to raise_error(Archive::NoNamespaceGiven)
            end
          end

          context "which doesn't exist" do
            let(:namespace) { 'my-renamed-book-repo' }

            it 'prints an error message and returns nil' do
              expect{ download }.to raise_error(Archive::FileDoesNotExist)
            end
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

        def create_s3_file(name, number)
          bucket.files.create :key => "#{name}-#{number}.tgz",
                              :body => tarball_with_contents("contents of #{name}-#{number}"),
                              :public => true
        end

      end

      describe '#upload_file' do
        it 'uploads to AWS bucket' do
          File.write(tmpdir.join('filename'), "I have a file")
          uploaded_file = archive.upload_file(bucket_key, 'filename', tmpdir.join('filename'))
          expect(uploaded_file.url(0)).
            to match(%r(^https://#{bucket_key}\.s3\.amazonaws\.com/filename))
        end
      end

      describe 'matching tarball names' do
        context 'using a regex' do
          it 'matches tarballs that follow the build number versioning convention' do
            filename = 'i-am-a-tarball-1.tgz'
            filename2 = 'i-am-a-tarball-1099.tgz'
            expect(filename).to match archive.tarball_name_regex('i-am-a-tarball')
            expect(filename2).to match archive.tarball_name_regex('i-am-a-tarball')
          end

          it 'matches tarballs that follow the timestamp versioning convention' do
            filename = 'i-am-a-tarball-20150520_1128.tgz'
            expect(filename).to match archive.tarball_name_regex('i-am-a-tarball')
          end
        end
      end
    end
  end
end
