require_relative '../../../../lib/bookbinder/config/section_config'
require_relative '../../../../lib/bookbinder/ingest/working_copy'
require_relative '../../../../lib/bookbinder/repositories/section_repository'

module Bookbinder
  module Repositories
    describe SectionRepository do
      let(:null_logger) { double('deprecated logger').as_null_object }
      let(:null_cloner) { ->(*) { Ingest::WorkingCopy.new } }
      let(:spy_cloner) {
        Class.new {
          attr_reader :clones

          def initialize
            @clones = []
          end

          def call(args)
            @clones << args
            Ingest::WorkingCopy.new
          end
        }.new
      }

      it "clones all sections into the provided destination dir" do
        SectionRepository.new(null_logger, spy_cloner).fetch(
          configured_sections: [
            Config::SectionConfig.new('repository' => { 'name' => 'myorg/myrepo' },
                                      'directory' => 'mydesireddir'),
            Config::SectionConfig.new('repository' => { 'name' => 'myorg/myotherrepo' },
                                      'directory' => nil),
          ],
          destination_dir: 'my/place/to/dump/repos'
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
        SectionRepository.new(null_logger, spy_cloner).fetch(
          configured_sections: [
            Config::SectionConfig.new('repository' => { 'name' => 'myorg/myrepo',
                                                        'ref' => 'mydesiredref' }),
            Config::SectionConfig.new('repository' => { 'name' => 'myorg/myotherrepo' }),
          ],
          destination_dir: 'anywhere/really',
          ref_override: 'actuallythisversionplz'
        )

        expect(spy_cloner.clones.map {|clone| clone[:source_ref]}).to eq([ 'actuallythisversionplz' ] * 2)
      end

      it "returns section representations" do
        working_copies = [
          Ingest::WorkingCopy.new(repo_dir: 'foo', copied_to: 'bar', directory: 'baz', full_name: 'qux'),
          Ingest::WorkingCopy.new(repo_dir: 'a', copied_to: 'b', directory: 'c', full_name: 'd'),
        ]

        n = -1
        cloner = ->(*) { working_copies[n += 1] }

        sections = SectionRepository.new(null_logger, cloner).fetch(
          configured_sections: [
            Config::SectionConfig.new('repository' => { 'name' => 'myorg/myrepo',
                                                        'ref' => 'mydesiredref' },
                                      'preprocessor_config' => {'my' => 'stuff', 'to' => 'preprocess'}),
            Config::SectionConfig.new('repository' => { 'name' => 'myorg/myotherrepo' },
                                      'subnav_template' => 'specified_a_template'),
          ],
          destination_dir: 'anywhere/really',
          ref_override: 'actuallythisversionplz'
        )

        expect(sections).to eq(
          [
            Section.new('bar', 'qux', copied = true, 'anywhere/really', 'baz', nil, 'my' => 'stuff', 'to' => 'preprocess'),
            Section.new('b', 'd', copied = true, 'anywhere/really', 'c', 'specified_a_template'),
          ]
        )
      end

      it "informs the user that it's fetching each repository" do
        logger = double('deprecated logger interface')

        expect(logger).to receive(:log).with(%r{Gathering .*foo/section})
        expect(logger).to receive(:log).with(%r{Gathering .*bar/section})

        SectionRepository.new(logger, null_cloner).fetch(
          configured_sections: [
            Config::SectionConfig.new('repository' => { 'name' => 'foo/section' }),
            Config::SectionConfig.new('repository' => { 'name' => 'bar/section' }),
          ],
          destination_dir: 'some/place'
        )
      end
    end
  end
end
