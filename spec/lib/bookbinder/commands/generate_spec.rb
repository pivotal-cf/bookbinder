require 'rack/test'
require_relative '../../../../lib/bookbinder/commands/collection'
require_relative '../../../../lib/bookbinder/commands/generate'
require_relative '../../../../lib/bookbinder/local_filesystem_accessor'
require_relative '../../../../lib/bookbinder/sheller'
require_relative '../../../helpers/use_fixture_repo'
require_relative '../../../helpers/dev_null'

module Bookbinder
  module Commands
    describe Generate do
      include Rack::Test::Methods

      use_fixture_repo

      UNUSED_FS = Object.new
      UNUSED_SHELLER = Object.new
      UNUSED_PATH = 'unused/path'
      let(:context_dir) { tmp_subdir('repositories') }

      def generate_cmd(fs: UNUSED_FS,
                       sheller: UNUSED_SHELLER,
                       context_dir: UNUSED_PATH,
                       streams: DevNull.get_streams)
        Generate.new(fs, sheller, context_dir, streams)
      end

      def suppress_ruby_warnings(&block)
        original_verbose, $VERBOSE = $VERBOSE, nil
        block.call
      ensure
        $VERBOSE = original_verbose
      end

      it "produces a book that can be bound and run, provided a valid config.yml" do
        generate = generate_cmd(fs: LocalFilesystemAccessor.new,
                                sheller: Sheller.new,
                                context_dir: context_dir,
                                streams: {out: StringIO.new,
                                          success: StringIO.new,
                                          err: $stderr})

        generate_result = generate.run('mynewbook', path: File.expand_path('../../../../..', __FILE__))
        expect(generate_result).to be_zero

        expect(context_dir.join('mynewbook/Gemfile.lock').exist?).to be_truthy

        Dir.chdir(context_dir.join('mynewbook')) do
          File.open('./config.yml', 'a') do |f|
            f << <<-YAML
sections:
- repository:
    name: fantastic/dogs-repo
    ref: 'dog-sha'
  directory: dogs
            YAML
          end

          result = Sheller.new.run_command('bin/bookbinder bind local',
                                           out: StringIO.new,
                                           err: StringIO.new)

          expect(result).to be_success
        end

        Dir.chdir(context_dir.join('mynewbook/final_app')) do
          app = suppress_ruby_warnings do
            Rack::Builder.parse_file(
              context_dir.join('mynewbook/final_app/config.ru').to_s
            ).first
          end

          session = Rack::Test::Session.new(app)

          session.get '/'
          expect(session.last_response).to be_ok
        end
      end

      it "logs what it's about to do, and successful result" do
        out = StringIO.new
        success = StringIO.new
        generate_cmd(fs: double('fs', file_exist?: false, make_directory: nil, write: nil),
                     sheller: double('sheller', run_command: double('status', success?: true)),
                     streams: {out: out, success: success, err: StringIO.new},
                     context_dir: 'my/context').
        run('foobar')
        expect(out.tap(&:rewind).read).to match(<<-MESSAGE)
Generating book at my/context/foobar...
        MESSAGE
        expect(success.tap(&:rewind).read).to match(<<-MESSAGE)
Successfully generated book at my/context/foobar
        MESSAGE
      end

      it "fails if the requested dir exists" do
        fs = double('fs')
        generate = generate_cmd(fs: fs, context_dir: 'context/dir')
        allow(fs).to receive(:file_exist?).with(Pathname('context/dir/existing')) { true }
        expect(generate.run('existing')).not_to be_zero
      end

      it "logs an error if requested dir exists" do
        fs = double('fs')
        err = StringIO.new
        generate = generate_cmd(
          fs: fs,
          context_dir: 'context/dir',
          streams: {out: StringIO.new, err: err}
        )
        allow(fs).to receive(:file_exist?) { true }
        generate.run('existing')

        expect(err.tap(&:rewind).read).to eq(<<-MESSAGE)
Cannot generate book: directory already exists
        MESSAGE
      end
    end
  end
end
