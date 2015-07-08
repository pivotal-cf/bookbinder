require_relative '../../../lib/bookbinder/sheller'

module Bookbinder
  describe Sheller do

    it 'redirects stdout to specified target' do
      sheller = Sheller.new
      out = StringIO.new
      sheller.run_command("echo 'hello'", out: out)
      out.rewind
      expect(out.read).to eq("hello\n")
    end

    it 'redirects stderr to specified target' do
      sheller = Sheller.new
      err = StringIO.new
      sheller.run_command(">&2 echo hello", err: err)
      err.rewind
      expect(err.read).to eq("hello\n")
    end

    it 'interleaves stdout and stderr' do
      shared = StringIO.new

      sheller = Sheller.new
      sheller.run_command(
        "echo first; sleep 0.01; >&2 echo second; sleep 0.01; >&1 echo third",
        out: shared, err: shared
      )
      shared.rewind
      expect(shared.read).to eq "first\nsecond\nthird\n"
    end

    it 'accepts environment variables as a parameter' do
      sheller = Sheller.new
      env_vars = {'KEY_1' => 'VALUE_1', 'KEY_2' => 'VALUE_2'}
      out = StringIO.new
      process_env_vars = 'echo "$KEY_1 $KEY_2"'
      sheller.run_command(env_vars, process_env_vars, out: out)
      out.rewind
      expect(out.read).to eq "VALUE_1 VALUE_2\n"
    end

    it 'returns the exit status' do
      sheller = Sheller.new
      result = sheller.run_command("exit 1")
      expect(result).not_to be_success
    end

    it 'sends un-redirected output to the abyss' do
      sheller = Sheller.new
      result = sheller.run_command("echo first; >&2 echo second")
      expect(result).to be_success
    end

    it 'has a simple way to get stdout from a command' do
      sheller = Sheller.new
      expect(sheller.get_stdout("which ls")).to eq("/bin/ls")
    end
  end
end
