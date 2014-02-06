require 'spec_helper'

describe CodeRepo do
  describe '.get_instance' do
    before do
      stub_github_for 'foo/book'
      stub_github_for 'foo/dogs-repo'
    end

    context 'when called more than once' do
      it 'always returns the same instance' do
        CodeRepo.get_instance('foo/book').object_id
          .should == CodeRepo.get_instance('foo/book').object_id

        CodeRepo.get_instance('foo/dogs-repo').object_id
          .should_not == CodeRepo.get_instance('foo/book').object_id
      end
    end
  end
end