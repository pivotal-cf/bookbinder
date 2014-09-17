require 'bookbinder/git_file_walker'

module Bookbinder

  describe GitFileWalker do
    it 'returns the most recent commit for every file' do
      tempdir = Dir.mktmpdir('git-walker-integration')
      git_object = Git.clone('https://github.com/Duckburg/scrooge.git', tempdir)
      git_object.checkout('54ef8f581b3542cbbca4219d7c69bf3d9831cdbe')
      file_walker = GitFileWalker.new(git_object)
      file_shas = file_walker.shas_by_file

      expect(file_shas).to eq(
                               'README.md' => '54ef8f581b3542cbbca4219d7c69bf3d9831cdbe',
                               'scrooge-mcduck.html' => 'dd5c81cd6f075c73b567776cdd8ae0dfffe7bc7b'
                           )
    end
  end
end