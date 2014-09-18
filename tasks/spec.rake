require 'rspec/core/rake_task'

namespace :spec do
  RSpec::Core::RakeTask.new(:unit)

  RSpec::Core::RakeTask.new(:integration) do |t|
    t.rspec_opts = "--tag integration"
  end
end
