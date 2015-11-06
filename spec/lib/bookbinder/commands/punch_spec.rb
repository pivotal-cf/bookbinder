require_relative '../../../../lib/bookbinder/commands/punch'
require_relative '../../../../lib/bookbinder/config/configuration'
require_relative '../../../../lib/bookbinder/ingest/git_accessor'

module Bookbinder
  describe Commands::Punch do
    it 'should tag the book, its sections, and layout repo' do
      config = Config::Configuration.parse(
        'book_repo' => 'myorg/bookrepo',
        'layout_repo' => 'myorg/layout-repo',
        'sections' => [
          {'repository' => {'name' => 'myotherorg/section1repo'}},
          {'repository' => {'name' => 'myotherorg/section1repo'}, 'directory' => 'dupedrepo'},
          {'repository' => {'name' => 'yetanotherorg/section2repo'}}
        ]
      )
      config_fetcher = double('config fetcher', fetch_config: config)
      git = instance_double('Bookbinder::Ingest::GitAccessor')

      expect(git).to receive(:remote_tag).with('git@github.com:myorg/bookrepo', "my-new-tag", "HEAD")
      expect(git).to receive(:remote_tag).with('git@github.com:myorg/layout-repo', "my-new-tag", "HEAD")
      expect(git).to receive(:remote_tag).with('git@github.com:myotherorg/section1repo', "my-new-tag", "HEAD")
      expect(git).to receive(:remote_tag).with('git@github.com:yetanotherorg/section2repo', "my-new-tag", "HEAD")

      punch = Commands::Punch.new(double('logger').as_null_object, config_fetcher, git)
      punch.run ["my-new-tag"]
    end

    it "logs success" do
      success = StringIO.new
      out = StringIO.new
      punch = Commands::Punch.new(
        {success: success, out: out},
        double(
          'config fetcher',
          fetch_config: Config::Configuration.new(
            book_repo: 'loggity/book',
            sections: []
          )
        ),
        double('git').as_null_object
      )

      punch.run ["my-great-tag"]

      expect(success.tap(&:rewind).read).to eq("Success!\n")
      expect(out.tap(&:rewind).read).to eq(
          "loggity/book and its sections were tagged with my-great-tag\n"
        )
    end

    context 'when no tag is supplied' do
      it 'raises an error' do
        punch = Commands::Punch.new(nil, nil, nil)
        expect { punch.run [] }.to raise_error(CliError::InvalidArguments)
      end
    end
  end
end
