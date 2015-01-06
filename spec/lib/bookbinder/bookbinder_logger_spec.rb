require 'spec_helper'

shared_examples_for 'a logger' do
  it 'logs' do
    expect { subject.log('message') }.to_not raise_error
  end

  it 'log_prints' do
    expect { subject.log_print('message') }.to_not raise_error
  end

  it 'warns' do
    expect { subject.warn('message') }.to_not raise_error
  end

  it 'errors' do
    expect { subject.error('message') }.to_not raise_error
  end

  it 'successes' do
    expect { subject.success('message') }.to_not raise_error
  end

  it 'notifies' do
    expect { subject.notify('message') }.to_not raise_error
  end
end

describe BookbinderLogger do
  before do
    allow(subject).to receive(:puts)
    allow(subject).to receive(:print)
  end
  
  it_behaves_like 'a logger'
end

describe NilLogger do
  it_behaves_like 'a logger'
end