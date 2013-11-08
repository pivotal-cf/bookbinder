class MiddlemanRunner

  include BookbinderLogger
  include ShellOut

  def run(final_app_dir, output_master_middleman_dir)
    log 'Running middleman...'
    shell_out "(cd #{output_master_middleman_dir} && middleman build)"
    FileUtils.cp_r File.join(output_master_middleman_dir, 'build/.'), File.join(final_app_dir, 'public')
  end
end