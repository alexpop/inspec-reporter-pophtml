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
you@machine $ inspec exec some_profile --reporter pophtml:report.html
```

Note the `2` in the reporter name. If you omit it and run `--reporter html` instead, you will run the legacy RSpec HTML reporter.

## Configuring the Plugin

The `pophtml` reporter requires no configuration to function. However, two options--`alternate_css_file` and `alternate_js_file`--are available for customization. The options are set in the JSON-formatted configuration file that Chef InSpec consumes. For details, see [our configuration file documentation](https://www.inspec.io/docs/reference/config/).

For example:

```json
{
  "version": "1.2",
  "plugins": {
    "inspec-reporter-pophtml": {
      "alternate_js_file":"/var/www/js/my-javascript.js",
      "alternate_css_file":"/var/www/css/my-style.css"
    }
  }
}
```

### alternate\_css\_file

Specifies the full path to the location of a CSS file that will be read and inlined into the HTML report. The default CSS will not be included.

### alternate\_js\_file

Specifies the full path to the location of a JavaScript file that will be read and inlined into the HTML report. The default JavaScript will not be included. The JavaScript file should implement at least a `pageLoaded()` function, which will be called by the `onload` event of the HTML `body` element.

### TODO

```
var sort_by_name = function(a, b) {
     if(a.innerHTML.toLowerCase() < b.innerHTML.toLowerCase()) return -1;
     if(a.innerHTML.toLowerCase() > b.innerHTML.toLowerCase()) return 1;
     return 0;
}

Controls: [Failed First/Profile Order]

Results: [Failed First (5)/Failed First (20)/Failed First (All)/Profile Order (5)/Profile Order (20)/Profile Order (All)]

Controls sort:
  F-P-S-W Order
  W-S-F-P Order
  P-S-W-F Order

  Failed First
  Passed First
  Profile Order

Results sort:
  Failed First (5)
  Failed First (50)
  Failed First (All)
  Profile Order (5)
  Profile Order (50)
  Profile Order (All)
```

## Developing This Plugin

Submit PR and will discuss, thank you!
