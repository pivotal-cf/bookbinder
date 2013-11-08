require 'spec_helper'

describe Cli do

  let(:cli) { Cli.new }

  def run
    cli.run arguments
  end

  context 'when no arguments are supplied' do
    let(:arguments) { [] }
    it 'should print a helpful message' do
      BookbinderLogger.should_receive(:log).with(/No command supplied/)
      run
    end
  end

  context 'when a command that is not recognized is supplied' do
    let(:arguments) { ['foo'] }
    it 'should print a helpful message' do
      BookbinderLogger.should_receive(:log).with(/Unrecognized command 'foo'/)
      run
    end
  end

  context 'when given the "publish" command' do
    let(:arguments) { ['publish'] }
    let(:fake_publish) { double }
    it 'should run the publish command' do
      fake_publish.should_receive(:run).with([])
      Cli::Publish.stub(:new) { fake_publish }
      run
    end

    it 'returns whatever the publish command returned' do
      fake_publish.should_receive(:run).with([]).and_return(42)
      Cli::Publish.stub(:new) { fake_publish }
      expect(run).to eq(42)
    end
  end

end