require_relative '../../../lib/bookbinder/dita_section_gatherer_factory'
require_relative '../../../lib/bookbinder/local_dita_section_gatherer'
require_relative '../../../lib/bookbinder/remote_dita_section_gatherer'

module Bookbinder
  describe DitaSectionGathererFactory do
    it 'produces a RemoteDitaSectionGatherer when the source location is from github' do
      expect(DitaSectionGathererFactory.new(nil, nil)
             .produce('github', '/cloned_dita_dir', '/local_dita_dir', nil)).
          to be_a Bookbinder::RemoteDitaSectionGatherer
    end

    it 'produces a LocalDitaSectionGatherer when the source location is from local' do
      expect(DitaSectionGathererFactory.new(nil, nil)
             .produce('local', '/cloned_dita_dir', '/local_dita_dir', nil)).
          to be_a Bookbinder::LocalDitaSectionGatherer
    end
  end
end