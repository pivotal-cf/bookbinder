require 'spec_helper'

describe Cli::BuildAndPushTarball do
  include_context 'tmp_dirs'
  around do |spec|
    @build_number = '17'

    temp_library = tmp_subdir 'markdown_repos'
    book_dir = File.join temp_library, 'book'
    FileUtils.cp_r 'spec/fixtures/markdown_repos/.', temp_library
    FileUtils.cd(book_dir) { spec.run }
  end

  it 'should call GreenBuildRepository#create with correct parameters' do
    ENV.stub(:[])
    ENV.stub(:[]).with('BUILD_NUMBER').and_return(@build_number)

    GreenBuildRepository.any_instance.should_receive(:create) do |args|
      args.should have_key(:build_number)
      args.should have_key(:bucket)
      args.should have_key(:namespace)

      args.fetch(:bucket).should == 'bucket-name-in-fixture-config'
      args.fetch(:build_number).should == @build_number
      args.fetch(:namespace).should == 'fixture-book-title'
    end

    Cli::BuildAndPushTarball.new.run []
  end
end