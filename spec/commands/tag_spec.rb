require 'spec_helper'

describe Cli::Tag do
  include_context 'tmp_dirs'

  let(:book_sha) { 26.times.map { (65 + rand(26)).chr }.join  }
  let(:desired_tag) { 12.times.map { (65 + rand(26)).chr }.join  }
  let(:book_title) { 'fantastic/red-mars' }
  let(:config_hash) do
    {
      'book_repo' => book_title,
      'sections' => []
    }
  end
  let(:config) { Configuration.new(config_hash) }

  before do
    allow(GitClient.get_instance).to receive(:create_tag!)
  end

  it 'should tag the book and its sections' do
    @book = expect_to_receive_and_return_real_now(Book, :new, {full_name: book_title, sections: []})
    expect(@book).to receive(:tag_self_and_sections_with).with(desired_tag)
    Cli::Tag.new(config).run [desired_tag]
  end

  context 'when no tag is supplied' do
    it 'raises a Cli::InvalidArguments error' do
      expect {
        Cli::Tag.new(config).run []
      }.to raise_error(Cli::InvalidArguments)
    end
  end
end
