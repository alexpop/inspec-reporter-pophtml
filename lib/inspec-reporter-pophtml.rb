libdir = File.dirname(__FILE__)
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require "inspec-reporter-pophtml/version"
module InspecPlugins
  module PopHtmlReporter
    class Plugin < ::Inspec.plugin(2)
      # Internal machine name of the plugin. InSpec will use this in errors, etc.
      plugin_name :'inspec-reporter-pophtml'

      # Define a new Reporter.
      reporter :pophtml do
        require "inspec-reporter-pophtml/reporter"
        InspecPlugins::PopHtmlReporter::Reporter
      end
    end
  end
end
