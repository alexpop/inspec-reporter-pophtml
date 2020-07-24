require_relative "../../../shared/core_plugin_test_helper.rb"
require_relative "../../lib/inspec-reporter-pophtml"
require_relative "../../lib/inspec-reporter-pophtml/reporter"

describe InspecPlugins::PopHtmlReporter::Reporter do
  [
    # API instance methods
    :render,
  ].each do |api_method|
    it "should implement a '#{api_method}' instance method" do
      klass = InspecPlugins::PopHtmlReporter::Reporter
      _(klass.method_defined?(api_method)).must_equal true
    end
  end

  [
    # API class methods
    :run_data_schema_constraints,
  ].each do |api_method|
    it "should implement a '#{api_method}' class method" do
      klass = InspecPlugins::PopHtmlReporter::Reporter
      _(klass.singleton_methods).must_include(api_method)
    end
  end

end
