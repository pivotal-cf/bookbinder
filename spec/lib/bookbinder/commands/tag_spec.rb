require_relative '../../../../lib/bookbinder/commands/tag'
require_relative '../../../../lib/bookbinder/config/configuration'
require_relative '../../../../lib/bookbinder/ingest/git_accessor'

module Bookbinder
  describe Commands::Tag do
    it 'should tag the book and its sections' do
      config = Config::Configuration.parse(
        'book_repo' => 'myorg/bookrepo',
        'sections' => [
          {'repository' => {'name' => 'myotherorg/section1repo'}},
          {'repository' => {'name' => 'myotherorg/section1repo'}, 'directory' => 'duped-repo'},
          {'repository' => {'name' => 'yetanotherorg/section2repo'}}
        ]
      )
      config_fetcher = double('config fetcher', fetch_config: config)
      git = instance_double('Bookbinder::GitAccessor')

      expect(git).to receive(:remote_tag).with('git@github.com:myorg/bookrepo', "my-new-tag", "HEAD")
      expect(git).to receive(:remote_tag).with('git@github.com:myotherorg/section1repo', "my-new-tag", "HEAD")
      expect(git).to receive(:remote_tag).with('git@github.com:yetanotherorg/section2repo', "my-new-tag", "HEAD")

      tag = Commands::Tag.new(double('logger').as_null_object, config_fetcher, git)
      tag.run ["my-new-tag"]
    end

    it "logs success" do
      success = StringIO.new
      out = StringIO.new
      tag = Commands::Tag.new(
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

      tag.run ["mygreattag"]

      expect(success.tap(&:rewind).read).to eq("Success!\n")
      expect(out.tap(&:rewind).read).to eq(
        "loggity/book and its sections were tagged with mygreattag\n"
      )
    end

    context 'when no tag is supplied' do
      it 'raises an error' do
        tag = Commands::Tag.new(nil, nil, nil)
        expect { tag.run [] }.to raise_error(CliError::InvalidArguments)
      end
    end
  end
end
