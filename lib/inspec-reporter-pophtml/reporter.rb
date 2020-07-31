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

      report_extras = {
        'report_id' => SecureRandom.uuid,
        'node_id'   => 'NOT_SPECIFIED',
        'node_name' => 'NOT_SPECIFIED',
        'tags'      => ['NOT','SPECIFIED'],
        'profiles'  => {},
        'sums'      => {},
        'status'    => '',
        'end_time' => Time.now.utc.to_datetime.rfc3339,
        'product'   => Inspec::Dist::PRODUCT_NAME,
        'product_version' => run_data.version
      }

      calculate_controls_sums(report_extras)
      calculate_statuses(report_extras)

      report_json_data=report_extras.to_json

      template = ERB.new(File.read(template_path + "/body.html.erb"))
      output(template.result(binding))
    end

    def self.run_data_schema_constraints
      "~> 0.0"
    end

    # Calculates control sums based on their status
    def calculate_controls_sums(extras)
      sums_report = {
        'failed' => 0,
        'passed' => 0,
        'skipped' => 0,
        'waived' => 0,
        'total' => 0
      }
      if run_data['profiles'] != nil && run_data['profiles'].length > 0
        run_data['profiles'].each do |profile|
          sums_profile = {
            'failed' => 0,
            'passed' => 0,
            'skipped' => 0,
            'waived' => 0,
            'total' => 0
          }
          if profile['controls'] != nil && profile['controls'].length > 0
            profile['controls'].each do |control|
              sums_profile[status(control)] += 1
            end
            sums_profile['total'] = sums_profile['failed'] + sums_profile['passed'] + sums_profile['skipped'] + sums_profile['waived']
            extras['profiles'][profile.sha256] = {
              'name' => profile.name,
              'version' => profile.version
            }
            extras['profiles'][profile.sha256]['sums'] = sums_profile

            sums_report['failed'] += sums_profile['failed']
            sums_report['passed'] += sums_profile['passed']
            sums_report['skipped'] += sums_profile['skipped']
            sums_report['waived'] += sums_profile['waived']
          end
        end
      end
      sums_report['total'] = sums_report['failed'] + sums_report['passed'] + sums_report['skipped'] + sums_report['waived']
      extras['sums'] = sums_report
    end


    # Calculates report and profile statuses for reporting
    def calculate_statuses(extras)
      # Profile level 'status' & 'status_message' are new to inspec (v4.22.0+)
      # and are used to flag incompatibilities (target) or issues with the profiles
      skipped_profiles = 0
      failed_profiles = 0
      if run_data['profiles'] != nil && run_data['profiles'].length > 0
        run_data['profiles'].each do |profile|
          if profile['status'] == 'failed'
            failed_profiles += 1
          elsif profile['status'] == 'skipped'
            skipped_profiles += 1
          else
            if profile['status'].to_s == '' || profile['status'] == 'loaded'
              extras['profiles'][profile.sha256]['status'] = status_from_sums(extras['profiles'][profile.sha256]['sums'])
            else
              extras['profiles'][profile.sha256]['status'] = profile['status']
            end
          end
        end
      end

      if failed_profiles > 0
        extras['status'] = 'failed'
      elsif skipped_profiles > 0 && skipped_profiles == run_data['profiles'].length
        extras['status'] = 'skipped'
      else
        # Derive the status of a report from the controls
        extras['status'] = status_from_sums(extras['sums'])
      end
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

    # Returns the status from the results of a control
    def status_from_sums(sums)
      status = 'passed'
      if sums['failed'] > 0
        status = 'failed'
      elsif sums['total'] == sums['skipped'] && sums['skipped'] > 0
        status = 'skipped'
      elsif sums['total'] == sums['waived'] && sums['waived'] > 0
        status = 'waived'
      end
      return status
    end
  end
end
