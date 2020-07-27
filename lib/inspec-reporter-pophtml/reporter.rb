require 'erb'
require 'inspec/config'
require 'securerandom'

module InspecPlugins::PopHtmlReporter
  class Reporter < Inspec.plugin(2, :reporter)
    def render
      template_path = File.expand_path(__FILE__ + "../../../../templates")

      # Read config data from the user's config file. Supports two settings, both of which are absolute filesystem paths:
      #  alternate_css_file - contents will be used instead of default CSS
      #  alternate_js_file - contents will be used instead of default JavaScript
      cfg = Inspec::Config.cached.fetch_plugin_config("inspec-reporter-pophtml")
      js_path = cfg[:alternate_js_file] || (template_path + "/default.js")
      css_path = cfg[:alternate_css_file] || (template_path + "/default.css")

      report_uuid = SecureRandom.uuid
      control_sums = calculate_controls_sums()

      template = ERB.new(File.read(template_path + "/body.html.erb"))
      output(template.result(binding))
    end

    def self.run_data_schema_constraints
      "~> 0.0"
    end

    # Sums up the controls based on their status
    def calculate_controls_sums()
      sums = {
        'failed' => 0,
        'passed' => 0,
        'skipped' => 0,
        'waived' => 0
      }
      if run_data['profiles'] != nil && run_data['profiles'].length > 0
        run_data['profiles'].each do |profile|
          if profile['controls'] != nil && profile['controls'].length > 0
            profile['controls'].each do |control|
              sums[status(control)] += 1
            end
          end
        end
      end
      return sums
    end

    # Returns the status of a control
    def status(control)
      cwd = control['waiver_data']
      if cwd != nil && cwd != Inspec::RunData::Control::WaiverData.new({}) && !cwd['message'].start_with?('Waiver expired')
        return 'waived'
      else
        return results_status(control)
      end
    end

    # Returns the status from the results of a control
    def results_status(control)
      status = 'passed'
      if control['results'] != nil && control['results'].length > 0
        control['results'].each do |result|
          if result.status == 'failed'
            status = 'failed'
            break
          elsif result.status == 'skipped'
            status = 'skipped'
            break
          end
        end
      end
      return status
    end
    
  end
end
