require_relative '../../../../lib/bookbinder/config/section_config'
require_relative '../../../../lib/bookbinder/ingest/section_repository'
require_relative '../../../../lib/bookbinder/ingest/working_copy'

module Bookbinder
  module Ingest
    describe SectionRepository do
      let(:null_cloner) { ->(*) { Ingest::WorkingCopy.new(copied_to: 'some/place') } }
      let(:null_streams) { double('unused stream').as_null_object }
      let(:spy_cloner) {
        Class.new {
          attr_reader :clones

          def initialize
            @clones = []
          end

          def call(args)
            @clones << args
            Ingest::WorkingCopy.new(copied_to: 'some/place')
          end
        }.new
      }

      it "clones all sections into the provided destination dir" do
        SectionRepository.new.fetch(
          configured_sections: [
            Config::SectionConfig.new('repository' => { 'name' => 'myorg/myrepo' },
                                      'directory' => 'mydesireddir'),
            Config::SectionConfig.new('repository' => { 'name' => 'myorg/myotherrepo' },
                                      'directory' => nil),
          ],
          destination_dir: 'my/place/to/dump/repos',
          cloner: spy_cloner,
          streams: null_streams
        )

        expect(spy_cloner.clones).to eq(
          [
            {source_repo_name: 'myorg/myrepo',
             source_ref: 'master',
             destination_parent_dir: 'my/place/to/dump/repos',
             destination_dir_name: 'mydesireddir'},
            {source_repo_name: 'myorg/myotherrepo',
             source_ref: 'master',
             destination_parent_dir: 'my/place/to/dump/repos',
             destination_dir_name: nil},
          ]
        )
      end

      it "can override all refs" do
        SectionRepository.new.fetch(
          configured_sections: [
            Config::SectionConfig.new('repository' => { 'name' => 'myorg/myrepo',
                                                        'ref' => 'mydesiredref' }),
            Config::SectionConfig.new('repository' => { 'name' => 'myorg/myotherrepo' }),
          ],
          destination_dir: 'anywhere/really',
          ref_override: 'actuallythisversionplz',
          cloner: spy_cloner,
          streams: null_streams
        )

        expect(spy_cloner.clones.map {|clone| clone[:source_ref]}).to eq([ 'actuallythisversionplz' ] * 2)
      end

      it "returns section representations" do
        working_copies = [
          Ingest::WorkingCopy.new(copied_to: 'bar', full_name: 'qux'),
          Ingest::WorkingCopy.new(copied_to: 'b', full_name: 'd'),
        ]

        n = -1
        cloner = ->(*) { working_copies[n += 1] }

        sections = SectionRepository.new.fetch(
          configured_sections: [
            Config::SectionConfig.new(
              'directory' => 'my-desired-dir-name',
              'preprocessor_config' => {'my' => 'stuff', 'to' => 'preprocess'},
              'repository' => { 'name' => 'myorg/myrepo', 'ref' => 'mydesiredref' }
            ),
            Config::SectionConfig.new(
              'repository' => { 'name' => 'myorg/myotherrepo' },
              'subnav_template' => 'specified_a_template'
            ),
          ],
          destination_dir: 'anywhere/really',
          ref_override: 'actuallythisversionplz',
          cloner: cloner,
          streams: null_streams
        )

        expect(sections).to eq(
          [
            Section.new(Pathname('bar'), 'qux', 'my-desired-dir-name', nil, 'my' => 'stuff', 'to' => 'preprocess'),
            Section.new(Pathname('b'), 'd', nil, 'specified_a_template', {}),
          ]
        )
      end

      it "informs the user that it's fetching each repository" do
        colorized_stream = instance_double('Streams::ColorizedStream')
        streams = {success: colorized_stream}

        expect(colorized_stream).to receive(:puts).with(%r{Gathering .*foo/section})
        expect(colorized_stream).to receive(:puts).with(%r{Gathering .*bar/section})

        SectionRepository.new.fetch(
          configured_sections: [
            Config::SectionConfig.new('repository' => { 'name' => 'foo/section' }),
            Config::SectionConfig.new('repository' => { 'name' => 'bar/section' }),
          ],
          destination_dir: 'some/place',
          cloner: null_cloner,
          streams: streams
        )
      end
    end
  end
end
