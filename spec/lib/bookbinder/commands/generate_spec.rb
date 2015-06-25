require 'rack/test'
require_relative '../../../../lib/bookbinder/commands/collection'
require_relative '../../../../lib/bookbinder/commands/generate'
require_relative '../../../../lib/bookbinder/local_file_system_accessor'
require_relative '../../../../lib/bookbinder/sheller'

module Bookbinder
  module Commands
    describe Generate do
      include Rack::Test::Methods

      UNUSED_FS = Object.new
      UNUSED_SHELLER = Object.new
      UNUSED_PATH = 'unused/path'
      UNUSED_LOGGER = Object.new
      UNCHECKED_STREAMS = {out: StringIO.new, err: StringIO.new}

      def generate_cmd(fs: UNUSED_FS,
                       sheller: UNUSED_SHELLER,
                       context_dir: UNUSED_PATH,
                       streams: UNCHECKED_STREAMS)
        Generate.new(fs, sheller, context_dir, streams)
      end

      def suppress_ruby_warnings(&block)
        original_verbose, $VERBOSE = $VERBOSE, nil
        block.call
      ensure
        $VERBOSE = original_verbose
      end

      it "produces a book that can be bound and run" do
        Dir.mktmpdir do |tmpdir|
          path = Pathname(tmpdir)
          generate = generate_cmd(fs: LocalFileSystemAccessor.new,
                                  sheller: Sheller.new,
                                  context_dir: path,
                                  streams: {out: StringIO.new,
                                            success: StringIO.new,
                                            err: $stderr})
          expect(generate.run(%w(mynewbook))).to be_zero

          expect(path.join('mynewbook/Gemfile.lock').exist?).to be_truthy

          Dir.chdir(path.join('mynewbook')) do
            result = Sheller.new.run_command('bin/bookbinder bind local',
                                             out: StringIO.new,
                                             err: StringIO.new)
            expect(result).to be_success
          end

          Dir.chdir(path.join('mynewbook/final_app')) do
            app = suppress_ruby_warnings do
              Rack::Builder.parse_file(
                path.join('mynewbook/final_app/config.ru').to_s
              ).first
            end

            session = Rack::Test::Session.new(app)

            session.get '/'
            expect(session.last_response).to be_ok
          end
        end
      end

      it "is available as a command" do
        commands = Commands::Collection.new(
          UNUSED_LOGGER, UNCHECKED_STREAMS, double('vcs')
        )
        expect(commands.detect {|c| c.command_for?('generate')}).to be_a(Generate)
      end

      it "is not a flag (used by help)" do
        expect(generate_cmd).not_to be_flag
      end

      it "is compatible with the help command" do
        help = Commands::Help.new(UNUSED_LOGGER, [generate_cmd])
        expect(help.usage_message).to include('generate')
      end

      it "logs what it's about to do, and successful result" do
        out = StringIO.new
        success = StringIO.new
        generate_cmd(fs: double('fs', file_exist?: false, make_directory: nil, write: nil),
                     sheller: double('sheller', run_command: double('status', success?: true)),
                     streams: {out: out, success: success, err: StringIO.new},
                     context_dir: 'my/context').
        run(%w(foobar))
        expect(out.tap(&:rewind).read).to match(<<-MESSAGE)
Generating book at my/context/foobar…
        MESSAGE
        expect(success.tap(&:rewind).read).to match(<<-MESSAGE)
Successfully generated book at my/context/foobar
        MESSAGE
      end

      it "fails if the requested dir exists" do
        fs = double('fs')
        generate = generate_cmd(fs: fs, context_dir: 'context/dir')
        allow(fs).to receive(:file_exist?).with(Pathname('context/dir/existing')) { true }
        expect(generate.run(%w(existing))).not_to be_zero
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
        generate.run(%w(existing))

        expect(err.tap(&:rewind).read).to eq(<<-MESSAGE)
Cannot generate book: directory already exists
        MESSAGE
      end
    end
  end
end
