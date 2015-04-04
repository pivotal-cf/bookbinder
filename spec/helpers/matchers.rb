RSpec::Matchers.define :have_output do |regexp|
  raise ArgumentError, "Must provide a regexp" if regexp.nil?
  chain(:in_red) do
    @color = Regexp.escape("\e[31m")
  end
  chain(:in_yellow) do
    @color = Regexp.escape("\e[33m")
  end
  chain(:in_bold_white) do
    @color = Regexp.escape("\e[1;39;49m")
  end
  match do |output|
    output.match(/#{@color}.*#{regexp}/im)
  end
  failure_message do |output|
    "Expected #{"colorized " if @color}regexp '#{regexp}' to be in output:\n#{output}"
  end
end
