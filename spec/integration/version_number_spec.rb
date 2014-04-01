require 'spec_helper'

describe 'calling bookbinder with --version' do
  let(:version) { Gem::Specification::load(File.join GEM_ROOT, "bookbinder.gemspec").version }

  it 'outputs the version' do
    expect(`#{GEM_ROOT}/bin/bookbinder --version`).to eq("bookbinder #{version}\n")
  end
end
