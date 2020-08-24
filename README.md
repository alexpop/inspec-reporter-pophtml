# inspec-reporter-pophtml Plugin

An eye-popping HTML output reporter specifically for Chef InSpec. The reporter knows about Chef InSpec structures like Controls and Profiles, and includes full metadata such as control tags, etc.

## To Install This Plugin

This plugin ships with Chef InSpec and requires no installation.

It should appear when you run:

```
you@machine $ git clone https://github.com/alexpop/inspec-reporter-pophtml.git
you@machine $ inspec plugin install inspec-reporter-pophtml
```

## How to use this plugin

To generate an HTML report using this plugin and save the output to a file named `report.html`, run:

```
you@machine $ inspec exec some_profile --reporter pophtml:/tmp/report.html
```

Note the `pophtml` in the reporter name.

## Configuring the Plugin

The `pophtml` reporter requires no configuration to function. However, two options--`alternate_css_file` and `alternate_js_file`--are available for customization. The options are set in the JSON-formatted configuration file that Chef InSpec consumes. For details, see [our configuration file documentation](https://www.inspec.io/docs/reference/config/).

For example:

```json
{
  "version": "1.2",
  "plugins": {
    "inspec-reporter-pophtml": {
      "alternate_js_file":"/var/www/js/my-javascript.js",
      "alternate_css_file":"/var/www/css/my-style.css",
      "report_uuid": "f3f640f6-8a64-4aaa-b142-555555555555"
    }
  }
}
```

See below all customization options available:

| Option               |      Description      |
|----------------------|:-------------:|
| `alternate_js_file`  | Full path to a javascript file instead of the default `default.js` that will be inlined into the HTML report. The default JavaScript will not be included. The JavaScript file should implement at least a `pageLoaded()` function, which will be called by the `onload` event of the HTML `body` element. |
| `alternate_css_file` | Full path to a stylesheet file instead of the default `default.css` that will be inlined into the HTML report.  |
| `alternate_preety_js_file`  | Full path to a prettify javascript file instead of the default `code_prettify.js` |
| `alternate_preety_css_file` | Full path to a prettify stylesheet file instead of the default `code_prettify_dark.css` |
| `max_results_per_control`   | Number of results per control to show when results are expanded. Defaults to 3 |
| `report_id` | Give an ID to this report, otherwise a random UUID will be generated. |
| `node_id`   | Give an ID to this node, defaults to 'NOT_SPECIFIED'. |
| `node_name` | Give a name to this node, defaults to 'NOT_SPECIFIED'. |
| `tags`      | Array of tags for this report, defaults to ['NOT','SPECIFIED'] |

### How to use a config json

A sample configuration file `sample-config.json` can be found in this repository. Here's an example exec with a config file where you can customize some of the defaults in the plugin.

```json
you@machine $ inspec exec some_profile --reporter pophtml:/tmp/report.html --config sample-config.json
```

### TODO

* Delay tooltips


## Developing This Plugin

Submit PR and will discuss, thank you!
