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
      preety_js_path = cfg[:alternate_preety_js_file] || (template_path + "/run_prettify.js")
      preety_css_path = cfg[:alternate_preety_js_file] || (template_path + "/run_prettify_dark.css")
      max_results_per_control = cfg[:max_results_per_control] || 5

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
      sort_and_truncate_control_results(max_results_per_control)

      report_json_data = report_extras.to_json

      template = ERB.new(File.read(template_path + "/body.html.erb"))
      output(template.result(binding))
    end

    def self.run_data_schema_constraints
      "~> 0.0"
    end

    # Calculates control sums based on their status
    def calculate_controls_sums(extras)
      # Summary of the status of all controls for a report (across one or multiple profiles)
      report_control_stats = {
        'failed' => 0,
        'passed' => 0,
        'skipped' => 0,
        'waived' => 0,
        'total' => 0
      }
      extras['sums'] = report_control_stats
      if run_data['profiles'] != nil && run_data['profiles'].length > 0
        run_data['profiles'].each do |profile|
          # Summary of the status of all controls for a profile
          profile_control_stats = {
            'failed' => 0,
            'passed' => 0,
            'skipped' => 0,
            'waived' => 0,
            'total' => 0
          }
          extras['profiles'][profile.sha256] = {
            'name'     => profile.name,
            'version'  => profile.version,
            'sums'     => profile_control_stats,
            'controls' => {}
          }
          if profile['controls'] != nil && profile['controls'].length > 0
            profile['controls'].each do |control|
              # Summary of the status of all results for a control
              control_result_stats = {
                'failed' => 0,
                'passed' => 0,
                'skipped' => 0,
                'total' => 0
              }
              extras['profiles'][profile.sha256]['controls'][control.id] = { 'sums' => control_result_stats }
              if control['results'] != nil && control['results'].length > 0
                control['results'].each do |result|
                  control_result_stats[result.status] += 1
                end
                control_result_stats['total'] = control_result_stats['failed'] + control_result_stats['passed'] + control_result_stats['skipped']
                extras['profiles'][profile.sha256]['controls'][control.id] = { 'sums' => control_result_stats }
              end
              profile_control_stats[control_status(control, control_result_stats)] += 1
            end
            profile_control_stats['total'] = profile_control_stats['failed'] + profile_control_stats['passed'] + profile_control_stats['skipped'] + profile_control_stats['waived']
            extras['profiles'][profile.sha256]['sums'] = profile_control_stats

            report_control_stats['failed'] += profile_control_stats['failed']
            report_control_stats['passed'] += profile_control_stats['passed']
            report_control_stats['skipped'] += profile_control_stats['skipped']
            report_control_stats['waived'] += profile_control_stats['waived']
          end
        end
      end
      report_control_stats['total'] = report_control_stats['failed'] + report_control_stats['passed'] + report_control_stats['skipped'] + report_control_stats['waived']
      extras['sums'] = report_control_stats
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
    def control_status(control, control_result_stats)
      cwd = control['waiver_data']
      if cwd != nil && cwd != Inspec::RunData::Control::WaiverData.new({}) && !cwd['message'].start_with?('Waiver expired')
        return 'waived'
      else
        return status_from_sums(control_result_stats)
      end
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

    def sort_and_truncate_control_results(max_results)
      run_data['profiles'].each do |profile|
        next unless run_data['controls'].is_a?(Array)
        profile['controls'].each do |control|
          next unless control['results'].is_a?(Array)
          control['results'].each_with_index do |result,result_index|
            # The unused 'backtrace' becomes the placeholder for the original index of the result. Then we sort.
            result['backtrace'] = result_index
          end
          res = control['results']
          truncated = { failed: 0, skipped: 0, passed: 0 }
          res.sort_by! do |r|
            # Replacing "skipped" with "kipped" for the sort logic so that
            # the results are sorted in this order: failed, skipped, passed
            r['status'] == 'skipped' ? 'kipped' : r['status']
          end
        end
      end
    end
  end
end
