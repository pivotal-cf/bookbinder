require 'spec_helper'
require 'bookbinder/git_file_walker'
require 'git'

module Bookbinder
  describe GitFileWalker do
    #                  tree1
    #            +-------+---------+
    #            |       |         |
    #            |       |         |
    #            v       v         v
    #          tree2   blob1     blob2
    #            +
    #            |
    #      +-----+----+
    #      |          |
    #      v          v
    #    tree3      blob3
    #      +
    #  +---+----+
    #  v        v
    #  blob4  blob5

    let(:tree1) do
      double(Git::Object::Tree,
             subtrees: {
                 'tree2' => tree2},
             blobs: {
                 'blob1' => blob1,
                 'blob2' => blob2},
      )
    end
    let(:tree2) do
      double(Git::Object::Tree,
             subtrees: {
                 'tree3' => tree3},
             blobs: {
                 'blob3' => blob3})
    end
    let(:tree3) do
      double(Git::Object::Tree,
             blobs: {
                 'blob4' => blob4,
                 'blob5' => blob5},
             subtrees: {})
    end

    let(:blob1) { double(Git::Object::Blob) }
    let(:blob2) { double(Git::Object::Blob) }
    let(:blob3) { double(Git::Object::Blob) }
    let(:blob4) { double(Git::Object::Blob) }
    let(:blob5) { double(Git::Object::Blob) }

    let(:blob1_sha) { 'blob1-sha' }
    let(:blob2_sha) { 'blob2-sha' }
    let(:blob3_sha) { 'blob3-sha' }
    let(:blob4_sha) { 'blob4-sha' }
    let(:blob5_sha) { 'blob5-sha' }

    let(:git_object) { double(Git::Base) }

    before do
      allow(git_object).to receive(:gtree).with('HEAD').and_return(tree1)

      log = double(Git::Log)
      allow(git_object).to receive(:log).and_return(log)

      commit1 = double(Git::Object::Commit, sha: blob1_sha)
      allow(log).to receive(:object).with('blob1').and_return [commit1]

      commit2 = double(Git::Object::Commit, sha: blob2_sha)
      allow(log).to receive(:object).with('blob2').and_return [commit2]

      commit3 = double(Git::Object::Commit, sha: blob3_sha)
      allow(log).to receive(:object).with('tree2/blob3').and_return [commit3]

      commit4 = double(Git::Object::Commit, sha: blob4_sha)
      allow(log).to receive(:object).with('tree2/tree3/blob4').and_return [commit4]

      commit5 = double(Git::Object::Commit, sha: blob5_sha)
      allow(log).to receive(:object).with('tree2/tree3/blob5').and_return [commit5]
    end

    describe '#shas_by_file' do
      it 'returns a hash of all the files and shas' do
        expect(GitFileWalker.new(git_object).shas_by_file).to eq(
                                                                  'blob1' => 'blob1-sha',
                                                                  'blob2' => 'blob2-sha',
                                                                  'tree2/blob3' => 'blob3-sha',
                                                                  'tree2/tree3/blob4' => 'blob4-sha',
                                                                  'tree2/tree3/blob5' => 'blob5-sha')
      end
    end
  end
end