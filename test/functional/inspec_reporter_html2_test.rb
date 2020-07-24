require_relative "../../../shared/core_plugin_test_helper.rb"
require "tempfile"

describe "inspec-reporter-pophtml" do
  include CorePluginFunctionalHelper

  let(:output_file) { f = Tempfile.new(["temp", ".html"]); f.close; f.path }
  def teardown
    # Use force because the deletion may occasionally fail in parallel CI
    FileUtils.rm_f(output_file)
  end

  describe "when run on a basic profile" do
    # --no-distinct-exit is needed because this profile skips a control on windows
    let(:run_result) { run_inspec_process("exec #{profile_path}/old-examples/profile --no-distinct-exit --reporter pophtml:#{output_file}") }

    it "it should not crash inspec" do
      _(run_result.stderr.gsub("#< CLIXML\r\n", "")).must_be_empty
      _(run_result.exit_status).must_equal 0
    end

    it "should produce valid HTML" do
      # Our windows CI images are not setup for the HTML proofer libcurl DLLs
      # and we really only need to verify this on one platform
      return if is_windows?

      require "html-proofer"

      proofer_opts = {
        disable_external: true, # The old-example has 3 Ref links that are all 404s
        check_html: true,
        # Default of :info produces progress logs to stdout. At :warn it is silent
        # but will fail the test below if there is validation failure.
        log_level: :warn,
      }
      run_result

      _(proc { HTMLProofer.check_file(output_file, proofer_opts).run } ).must_be_silent
    end
  end

  describe "when run with alternate JS and CSS" do
    let(:run_result) { run_inspec_process("exec #{profile_path}/old-examples/profile --config lib/plugins/inspec-reporter-pophtml/test/fixtures/config.json --reporter pophtml:#{output_file}") }

    it "should include the alternate files" do
      run_result
      output = File.read(output_file)
      _(output).must_include "this is the alternate.js"
      _(output).must_include "this is the alternate.css"
    end
  end
end
