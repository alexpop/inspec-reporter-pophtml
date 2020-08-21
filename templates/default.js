var expanded_char = '▼';
var collapsed_char = '▶';
var shown_results = <%= max_results_per_control %>;
var profile_controls = {};
<% report_extras['profiles'].each do |key,value| %>
profile_controls["controls-<%= key %>"] = { 'shown': <%= value['sums']['total'] %>, 'total': <%= value['sums']['total'] %> };
<% end %>

/* CSS primitives */
function addCssClass(id, cls) {
  document.getElementById(id).className += (" " + cls);
}

function removeCssClass(id, cls) {
  var el = document.getElementById(id);
  var classes = el.className.replace(cls,'');
  el.className = classes;
}

function hideElement(element) {
  // console.log('Hiding ' + element.id);
  if (!element.className.includes(' hidden')) {
    element.className += (' hidden');
  }
}

function showElement(element) {
  // console.log('Showing ' + element.id);
  var classes = element.className.replace(' hidden','');
  element.className = classes;
}

function handleShowSource(evt) {
  var control_id = evt.srcElement.id.replace("show-code-", "")
  addCssClass(evt.srcElement.id, "hidden")
  removeCssClass("hide-code-" + control_id, "hidden")
  removeCssClass("source-code-" + control_id, "hidden")
}

function handleHideSource(evt) {
  var control_id = evt.srcElement.id.replace("hide-code-", "")
  addCssClass(evt.srcElement.id, "hidden")
  addCssClass("source-code-" + control_id, "hidden")
  removeCssClass("show-code-" + control_id, "hidden")
}

function handleSelectorChange(evt) {
  var should_show = evt.srcElement.checked
  var which_group = evt.srcElement.id.replace("-checkbox","")
  var controls = document.getElementsByClassName("control-status-" + which_group)
  var i;
  if (should_show) {
    for (i = 0; i < controls.length; i++) {
      var control_profile_sha = controls[i].parentElement.id;
      var label = document.getElementById('label-' + control_profile_sha).innerText;
      if (label[0] == expanded_char) {
        // Only show element if the Controls are expanded for this profile
        showElement(controls[i]);
      }
      profile_controls[controls[i].parentElement.id]['shown']++;
    }
  } else {
    for (i = 0; i < controls.length; i++) {
      hideElement(controls[i]);
      profile_controls[controls[i].parentElement.id]['shown']--;
    }
  }
  var controls_labels = document.getElementsByClassName("controls-label");
  for (i = 0; i < controls_labels.length; i++) {
    controls_profile_sha = controls_labels[i].id.replace('label-', '');
    controls_labels[i].innerText = controls_labels[i].innerText[0] + ' Controls (' + profile_controls[controls_profile_sha]['shown'] + ' / ' + profile_controls[controls_profile_sha]['total'] + ')';
  }
}

function handleChildProfileChange(evt) {
  var should_show = evt.srcElement.checked
  var child_profiles = document.getElementsByClassName("child-profile")
  var i;
  if (should_show) {
    for (i = 0; i < child_profiles.length; i++) {
      showElement(child_profiles[i]);
    }
  } else {
    for (i = 0; i < child_profiles.length; i++) {
      hideElement(child_profiles[i]);
    }
  }
}

String.prototype.replaceAt = function(index, replacement) {
  return this.substr(0, index) + replacement + this.substr(index + replacement.length);
}

function controlsClicked(event) {
  var selectors = document.querySelectorAll('.' + event.id.replace('label-', ''));
  console.log('controlsClicked, '+ event.id + ' has ' + selectors.length + ' controls');
  var controls_label = event.innerText;
  if (controls_label[0] == expanded_char) {
    for (i = 0; i < selectors.length; i++) {
      hideElement(selectors[i]);
    }
    controls_label = controls_label.replaceAt(0, collapsed_char);
  } else {
    // When Controls are expanded, only show the control that are "checked" in the selector
    var failed_checked = document.getElementById("failed-checkbox").checked;
    var passed_checked = document.getElementById("passed-checkbox").checked;
    var skipped_checked = document.getElementById("skipped-checkbox").checked;
    var waived_checked = document.getElementById("waived-checkbox").checked;
    for (i = 0; i < selectors.length; i++) {
      var control_status = selectors[i].classList[1];
      if ((failed_checked && control_status == 'control-status-failed') ||
          (passed_checked && control_status == 'control-status-passed') ||
          (skipped_checked && control_status == 'control-status-skipped') ||
          (waived_checked && control_status == 'control-status-waived')) {
        showElement(selectors[i]);
      }
    }
    controls_label = controls_label.replaceAt(0, expanded_char);
  }
  event.innerText = controls_label;
}

function resultsClicked(event) {
  var selectors = document.querySelectorAll('.' + event.id);
  console.log('resultsClicked, ' + event.id + ' has ' + selectors.length + ' results');
  var results_label = event.innerText;
  if (results_label[0] == expanded_char) {
    for (i = 0; i < selectors.length; i++) {
      hideElement(selectors[i]);
    }
    results_label = collapsed_char + ' Results (0 / ' + selectors.length + ')';
  } else {
    shown_results_here = shown_results
    if (shown_results == 0) {
      shown_results_here = 1000000;
    }
    for (i = 0; i < selectors.length && i < shown_results_here; i++) {
      showElement(selectors[i]);
    }
    if (shown_results_here < selectors.length) {
      results_label = expanded_char + ' Results (' + shown_results_here + ' / ' + selectors.length + ')';
    } else {
      results_label = expanded_char + ' Results (' + selectors.length + ' / ' + selectors.length + ')';
    }
  }
  event.innerText = results_label;
}

function handleResultsChange(select) {
  shown_results = Number(select.value.slice(2));
  if (Number(select.value.slice(2)) != 0 && (!shown_results)) { shown_results = 1000000; }

  if (select.value.startsWith('ff')) {
    console.log("Got a Failed First selection (" +select.value+ ") with previous being: " + select.name);
    select.name = select.value;
    // Get all the controls in the report
    var controls = document.querySelectorAll('.control');
    console.log('Found ' + controls.length + ' looping...');
    for (i = 0; i < controls.length; i++) {
      // Get all results for the control
      results = controls[i].querySelectorAll('.result');
      for (j = 0; j < results.length; j++) {
        if (j < shown_results) {
          showElement(results[j]);
        } else {
          hideElement(results[j]);
        }
      }
    }
  } else {
    console.log("Must be a Profile Order selection");
  }
  updateResultsLabels();
}

function updateResultsLabels() {
  var results_labels = document.querySelectorAll('.results-label');
  for (i = 0; i < results_labels.length; i++) {
    var first_character = expanded_char;
    if (shown_results == 0) {
      first_character = collapsed_char;
    }
    var results = document.querySelectorAll('.'+results_labels[i].id);
    var new_label = '';
    if (shown_results < results.length) {
      // This is when we show less results than they are in total for the control
      new_label = first_character + ' Results (' + shown_results + ' / ' + results.length + ')'
    } else {
      new_label = first_character + ' Results (' + results.length + ' / ' + results.length + ')'
    }
    results_labels[i].innerText = new_label;
  }
}

function expandAll() {
  var selectors = document.querySelectorAll('.control');
  for (i = 0; i < selectors.length; i++) {
    showElement(selectors[i]);
  }
  var selectors = document.querySelectorAll('.result');
  for (i = 0; i < selectors.length; i++) {
    showElement(selectors[i]);
  }
}

window.onbeforeprint = function(event) {
  console.log("Printing detected, make all elements visible!");
  expandAll();
};

/* Main entry point */
function  pageLoaded() {
  var i;

  // wire up show source links
  var show_links = document.getElementsByClassName("show-source-code");
  for (i = 0; i < show_links.length; i++) {
    show_links[i].onclick = handleShowSource;
  }
  // wire up hide source links
  var hide_links = document.getElementsByClassName("hide-source-code");
  for (i = 0; i < hide_links.length; i++) {
    hide_links[i].onclick = handleHideSource;
  }
  // wire up selector checkboxes
  var selectors = document.getElementsByClassName("selector-checkbox");
  for (i = 0; i < selectors.length; i++) {
    selectors[i].onchange = handleSelectorChange;
  }
  // wire up child profile checkbox
  document.getElementById("child-profile-checkbox").onchange = handleChildProfileChange;

  report_time = document.getElementById("report-time");
  var utc_date = new Date(report_time.textContent);
  var tz = new Date().toString().split(" ")[5];
  report_time.textContent = utc_date.toLocaleString() + '  ' + tz;
  report_time.style.visibility = "visible";
}
