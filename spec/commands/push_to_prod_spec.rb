require 'spec_helper'

describe Cli::PushToProd do
  include_context 'tmp_dirs'

  around do |spec|
    @build_number = '17'
    @namespace = 'pdubs'

    temp_library = tmp_subdir 'markdown_repos'
    book_dir = File.join temp_library, 'book'
    FileUtils.cp_r 'spec/fixtures/markdown_repos/.', temp_library
    FileUtils.cd(book_dir) { spec.run }
  end

  it 'should call GreenBuildRepository#create with correct parameters' do
    fake_book = double
    Book.stub(:from_current_repo).and_return(fake_book)
    fake_book.stub(:short_name).and_return @namespace

    GreenBuildRepository.any_instance.should_receive(:download) do |args|
      args.should have_key(:download_dir)
      args.should have_key(:bucket)
      args.should have_key(:build_number)
      args.should have_key(:namespace)

      args.fetch(:bucket).should == 'bucket-name-in-fixture-config'
      args.fetch(:build_number).should == @build_number
      args.fetch(:namespace).should == @namespace
    end
    Cli::PushToProd.new.run [@build_number]
  end

  context 'when config is missing required keys' do
    before do
      File.stub(:read)
      YAML.stub(:load).and_return({foo: 'bar'})
    end

    it 'raises a "key not found" error' do
      expect { Cli::PushToProd.new.run @build_number }
        .to raise_exception KeyError
    end
  end
end