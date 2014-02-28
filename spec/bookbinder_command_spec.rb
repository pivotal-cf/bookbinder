require 'spec_helper'

describe Cli::BookbinderCommand do
  subject { described_class }

  it { should respond_to :usage_message }
  it { should respond_to :usage }
end
