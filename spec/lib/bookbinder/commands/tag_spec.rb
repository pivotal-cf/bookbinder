require_relative '../../../../lib/bookbinder/commands/tag'
require_relative '../../../../lib/bookbinder/config/configuration'
require_relative '../../../../lib/bookbinder/git_accessor'

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

    context 'when no tag is supplied' do
      it 'raises an error' do
        tag = Commands::Tag.new(nil, nil, nil)
        expect { tag.run [] }.to raise_error(CliError::InvalidArguments)
      end
    end
  end
end
