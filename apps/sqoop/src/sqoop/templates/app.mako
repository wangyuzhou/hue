## Licensed to Cloudera, Inc. under one
## or more contributor license agreements.  See the NOTICE file
## distributed with this work for additional information
## regarding copyright ownership.  Cloudera, Inc. licenses this file
## to you under the Apache License, Version 2.0 (the
## "License"); you may not use this file except in compliance
## with the License.  You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
<%!
  from desktop.views import commonheader, commonfooter
  from django.utils.translation import ugettext as _
%>

<%namespace name="actionbar" file="actionbar.mako" />

${ commonheader(None, "sqoop", user, "60px") | n,unicode }

<div class="container-fluid">
  <div id="sqoop-error" class="row-fluid mainSection hide">
    <h2>${_('Sqoop error')}</h2>
    <div class="error message well"></div>
  </div>

  <div id="jobs" class="row-fluid mainSection hide">
    <div id="jobs-list" class="row-fluid section hide">
      <div class="row-fluid" data-bind="if: !isLoading()">
        <%actionbar:render>
          <%def name="search()">
            <input id="filter" type="text" class="input-xlarge search-query" placeholder="${_('Search for job name or content')}">
          </%def>

          <%def name="actionbar()"></%def>

          <%def name="creation()">
            <a class="btn fileToolbarBtn" title="${_('Create a new job')}" href="#job/new"><i class="icon-plus-sign"></i> ${_('New job')}</a>
          </%def>
        </%actionbar:render>

        <!-- ko if: filteredJobs().length > 0 -->
        <ul class="major-list" data-bind="foreach: filteredJobs">
          <!-- ko if: submission() -->
          <li data-bind="routie: 'job/edit/' + id()" title="${ _('Click to edit') }">
            <div class="pull-right" style="padding-top: 5px">
              <a data-bind="visible: $.inArray(submission().status(), ['BOOTING', 'RUNNING']) > -1, routie: 'job/stop/' + id()"><i class="icon-stop"></i> ${_('Stop')}</a> &nbsp;
              <a data-bind="visible: $.inArray(submission().status(), ['BOOTING', 'RUNNING']) == -1, routie: 'job/run/' + id()"><i class="icon-play"></i> ${_('Run')}</a> &nbsp;
              <a data-bind="routie: 'job/copy/' + id()"><i class="icon-copy"></i> ${_('Copy')}</a> &nbsp;
              <a data-bind="visible: $.inArray(submission().status(), ['BOOTING', 'RUNNING']) == -1, routie: 'job/delete/' + id()"><i class="icon-remove"></i> ${_('Delete')}</a>
            </div>
            <h4 style="display: inline-block">
              <i class="icon-list"></i> <span data-bind="text: name"></span>
            </h4>
            &nbsp;
            <span class="label label-success" data-bind="visible: $.inArray(submission().status(), ['BOOTING', 'RUNNING', 'SUCCEEDED']) > -1">
              <span data-bind="visible: submission().status() != 'SUCCEEDED', text: submission().status, routie: 'job/status/' + id()"></span>
              <span data-bind="visible: submission().status() == 'SUCCEEDED', text: submission().createdFormatted, routie: 'job/status/' + id()"></span>
            </span>
            <span class="label label-warning" style="display: inline-block" data-bind="visible: $.inArray(submission().status(), ['FAILURE_ON_SUBMIT', 'FAILED', 'UNKNOWN']) > -1">
              <span data-bind="visible: submission().status() == 'UNKNOWN', text: submission().status"></span>
              <span data-bind="visible: submission().status() != 'UNKNOWN', text: submission().createdFormatted, routie: 'job/status/' + id()"></span>
            </span>
          </li>
          <!-- /ko -->

          <!-- ko ifnot: submission() -->
          <li data-bind="routie: 'job/edit/' + id()" title="${ _('Click to edit') }">
            <div class="pull-right" style="padding-top: 5px">
              <a data-bind="routie: 'job/run/' + id()"><i class="icon-play"></i> ${_('Run')}</a> &nbsp;
              <a data-bind="routie: 'job/copy/' + id()"><i class="icon-copy"></i> ${_('Copy')}</a> &nbsp;
              <a data-bind="routie: 'job/delete/' + id()"><i class="icon-remove"></i> ${_('Delete')}</a>
            </div>
            <h4 style="display: inline-block">
              <i class="icon-list"></i> <span data-bind="text: name"></span>
            </h4>
          </li>
          <!-- /ko -->
        </ul>
        <!-- /ko -->

        <div class="span10 offset1 center" data-bind="if: filteredJobs().length == 0">
          <h1 class="emptyMessage">${ _('There are currently no jobs.') }<br/>${ _('Please click on "New Job" to add one.') }</h1>
        </div>
      </div>

      <div class="row-fluid" data-bind="if: isLoading">
        <div class="span10 offset1 center">
          <i class="icon-spinner icon-spin" style="font-size: 60px; color: #DDD"></i>
        </div>
      </div>
    </div>

    <div id="job-editor" class="row-fluid section hide" data-bind="with: job">
      <div class="well sidebar-nav span2">
        <form id="advanced-settings" method="POST" class="form form-horizontal noPadding">
          <ul class="nav nav-list">
            <li class="nav-header">${_('Job')}</li>
            <li>
              <select name="type"
                      data-bind="'options': ['IMPORT', 'EXPORT'],
                                 'value': $root.job().type"
                      class="span12"></select>
            </li>
            <li class="nav-header">${_('Connection')}</li>
            <li>
              <select name="connection"
                      data-bind="'options': $root.persistedConnections,
                                 'optionsText': function(item) {
                                   return item.name();
                                 },
                                 'value': $root.connection"
                      class="span12"></select>
            </li>
            <li>
              <a href="#connection/new">
                <i class="icon-pencil"></i> ${ _('New connection') }
              </a>
            </li>
            <li data-bind="visible: $root.connections().length > 0">
              <a href="javascript:void(0);" data-bind="routie: 'connection/edit/' + $root.connection().id()">
                <i class="icon-reorder"></i> ${ _('Edit connection') }
              </a>
            </li>
            <li data-bind="visible: $root.connections().length > 0">
              <a href="#connection/delete">
                <i class="icon-trash"></i> ${ _('Delete connection') }
              </a>
            </li>
            <li class="nav-header" data-bind="visible: $root.job().persisted">${_('Actions')}</li>
            <li data-bind="visible: $root.job().persisted() && !$root.job().isRunning()">
              <a data-placement="right" rel="tooltip" title="${_('Run the job')}" href="#job/save-and-run">
                <i class="icon-play"></i> ${_('Run')}
              </a>
            </li>
            <li data-bind="visible: $root.job().isRunning()">
              <a data-placement="right" rel="tooltip" title="${_('Stop the job')}" href="#job/stop">
                <i class="icon-stop"></i> ${_('Stop')}
              </a>
            </li>
            <li data-bind="visible: $root.job().persisted">
              <a data-placement="right" rel="tooltip" title="${_('Copy the job')}" href="#job/copy">
                <i class="icon-copy"></i> ${_('Copy')}
              </a>
            </li>
            <li data-bind="visible: $root.job().persisted">
              <a data-placement="right" rel="tooltip" title="${_('Delete the job')}" href="#job/delete">
                <i class="icon-remove"></i> ${_('Delete')}
              </a>
            </li>
          </ul>
        </form>
      </div>

      <div id="job-forms" class="span10">
        <h3>${_('Create a job')}</h3>
        <form method="POST" class="form form-horizontal noPadding">
          <div class="control-group">
            <label class="control-label">${ _('Name') }</label>
            <div class="controls">
              <input name="connection-name" data-bind="value: name">
            </div>
          </div>
          <fieldset data-bind="foreach: connector">
            <div data-bind="foreach: inputs">
              <div data-bind="template: 'connector-' + type().toLowerCase()"></div>
            </div>
          </fieldset>
          <fieldset data-bind="foreach: framework">
            <div data-bind="foreach: inputs">
              <div data-bind="template: 'framework-' + type().toLowerCase()"></div>
            </div>
          </fieldset>
          <a href="#jobs" class="btn">${_('Cancel')}</a>
          <a href="#job/save" class="btn btn-primary">${_('Save')}</a>
        </form>
      </div>
    </div>

    <div id="connection-editor" class="row-fluid section hide" data-bind="with: editConnection">
      <div class="well sidebar-nav span2">
        <form id="advanced-settings" method="POST" class="form form-horizontal noPadding">
          <ul class="nav nav-list">
            <li class="nav-header">${_('Connector')}</li>
            <li>
              <select name="connector"
                      data-bind="'options': $root.connectors,
                                 'optionsText': function(item) {
                                   return item.name();
                                 },
                                 'optionsValue': function(item) {
                                   return item.id();
                                 },
                                 'value': connector_id"
                      class="span12"></select>
            </li>
            <li>&nbsp;</li>
            <li><a href="#connection/edit-cancel">${_('Back to job')}</a></li>
          </ul>
        </form>
      </div>

      <div id="connection-forms" class="span10">
        <h3>${_('Create a connection')}</h3>
        <form method="POST" class="form form-horizontal noPadding">
          <div class="control-group">
            <label class="control-label">${ _('Name') }</label>
            <div class="controls">
              <input name="connection-name" data-bind="value: name">
            </div>
          </div>
          <fieldset data-bind="foreach: connector">
            <div data-bind="foreach: inputs">
              <div data-bind="template: 'connector-' + type().toLowerCase()"></div>
            </div>
          </fieldset>
          <fieldset data-bind="foreach: framework">
            <div data-bind="foreach: inputs">
              <div data-bind="template: 'framework-' + type().toLowerCase()"></div>
            </div>
          </fieldset>
          <a href="#connection/edit-cancel" class="btn">${_('Cancel')}</a>
          <a href="#connection/save" class="btn btn-primary">${_('Save')}</a>
        </form>
      </div>
    </div>

    <div id="job-status" class="row-fluid section hide" data-bind="with: job">
      <div class="well sidebar-nav span2">
        <form id="advanced-settings" method="POST" class="form form-horizontal noPadding">
          <ul class="nav nav-list">
            <li>
              <a rel="tooltip" title="${_('Logs')}" href="javascript:void(0);" target="_new" data-bind="attr: {href: '/jobbrowser/jobs/' + $root.job().submission().external_id()}">
                <i class="icon-list"></i>
                ${_('Logs')}
              </a>
            </li>
            <li>
              <a rel="tooltip" title="${_('Back to editing a job')}" href="#job/edit">
                <i class="icon-arrow-left"></i>
                ${_('Back to job')}
              </a>
            </li>
          </ul>
        </form>
      </div>

      <div class="span10">
        <div class="progress center" data-bind="if: submission()">
          <div class="bar center" data-bind="style: {width: submission().progressFormatted, height: '100%'}, text: submission().progressFormatted">
            
          </div>
        </div>
      </div>
    </div>
  </div>
</div>

<script type="text/html" id="framework-enum">
<div class="control-group">
  <label class="control-label" data-bind="text: $root.label('framework', name())"></label>
  <div class="controls">
    <select data-bind="'options': values,
                       'value': value,
                       'optionsCaption': 'Choose...'">
  </div>
</div>
</script>

<script type="text/html" id="framework-map">
<div class="control-group">
  <label class="control-label" data-bind="text: $root.label('framework', name())"></label>
  <div class="controls">
    <input data-bind="value: value, attr: {'type': (sensitive() ? 'password' : 'text')}">
  </div>
</div>
</script>

<script type="text/html" id="framework-string">
<div class="control-group">
  <label class="control-label" data-bind="text: $root.label('framework', name())"></label>
  <div class="controls">
    <input data-bind="value: value, attr: {'type': (sensitive() ? 'password' : 'text')}">
  </div>
</div>
</script>

<script type="text/html" id="framework-integer">
<div class="control-group">
  <label class="control-label" data-bind="text: $root.label('framework', name())"></label>
  <div class="controls">
    <input data-bind="value: value, attr: {'type': (sensitive() ? 'password' : 'text')}">
  </div>
</div>
</script>

<script type="text/html" id="connector-enum">
<div class="control-group">
  <label class="control-label" data-bind="text: $root.label('connector', name())"></label>
  <div class="controls">
    <select data-bind="'options': values,
                       'value': value,
                       'optionsCaption': 'Choose...'">
  </div>
</div>
</script>

<script type="text/html" id="connector-map">
<div class="control-group">
  <label class="control-label" data-bind="text: $root.label('connector', name())"></label>
  <div class="controls">
    <input data-bind="value: value, attr: {'type': (sensitive() ? 'password' : 'text')}">
  </div>
</div>
</script>

<script type="text/html" id="connector-string">
<div class="control-group">
  <label class="control-label" data-bind="text: $root.label('connector', name())"></label>
  <div class="controls">
    <input data-bind="value: value, attr: {'type': (sensitive() ? 'password' : 'text')}">
  </div>
</div>
</script>

<script type="text/html" id="connector-integer">
<div class="control-group">
  <label class="control-label" data-bind="text: $root.label('connector', name())"></label>
  <div class="controls">
    <input data-bind="value: value, attr: {'type': (sensitive() ? 'password' : 'text')}">
  </div>
</div>
</script>

<script src="/static/ext/js/datatables-paging-0.1.js" type="text/javascript" charset="utf-8"></script>
<script src="/static/ext/js/routie-0.3.0.min.js" type="text/javascript" charset="utf-8"></script>
<script src="/static/ext/js/moment.min.js" type="text/javascript" charset="utf-8"></script>
<script src="/static/ext/js/knockout-min.js" type="text/javascript" charset="utf-8"></script>
<script src="/static/ext/js/knockout.mapping-2.3.2.js" type="text/javascript" charset="utf-8"></script>
<script src="/sqoop/static/js/cclass.js" type="text/javascript" charset="utf-8"></script>
<script src="/sqoop/static/js/koify.js" type="text/javascript" charset="utf-8"></script>
<script src="/sqoop/static/js/sqoop.utils.js" type="text/javascript" charset="utf-8"></script>
<script src="/sqoop/static/js/sqoop.models.js" type="text/javascript" charset="utf-8"></script>
<script src="/sqoop/static/js/sqoop.framework.js" type="text/javascript" charset="utf-8"></script>
<script src="/sqoop/static/js/sqoop.connectors.js" type="text/javascript" charset="utf-8"></script>
<script src="/sqoop/static/js/sqoop.connections.js" type="text/javascript" charset="utf-8"></script>
<script src="/sqoop/static/js/sqoop.jobs.js" type="text/javascript" charset="utf-8"></script>
<script src="/sqoop/static/js/sqoop.submissions.js" type="text/javascript" charset="utf-8"></script>
<script src="/sqoop/static/js/sqoop.js" type="text/javascript" charset="utf-8"></script>

<link rel="stylesheet" href="/sqoop/static/css/sqoop.css">

<script type="text/javascript" charset="utf-8">
//// Render all data
ko.applyBindings(viewModel, $('#jobs')[0]);

//// Events
$(document).on('connection_error.jobs', function(e, name, options, jqXHR) {
  $('#sqoop-error .message').text("${ _('Cannot connect to sqoop server.') }");
  routie('error');
});

$(document).on('start_error.job', function(e, job, options, error) {
  $.jHueNotify.error("${ _('Could not start job: ') }" + error.message);
});

$(document).on('start_fail.job', function(e, job, options, message) {
  $.jHueNotify.error("${ _('Could not start job: ') }" + message);
});

$(document).on('started.job', function(e, job, options, submission_dict) {
  $.jHueNotify.info("${ _('Started job.') }");
});

$(document).on('stopped.job', function(e, job, options, submission_dict) {
  $.jHueNotify.info("${ _('Stopped job.') }");
});

$(document).on('save_fail.connection', function(e, job, options, data) {
  $.each(job.errors(), function(index, error) {
    $.jHueNotify.error(error);
  });
});

$(document).on('keyup', 'input#filter', function() {
  viewModel.filter($('#filter').val());
});

$("#jobs-list tbody").on('click', 'tr', function() {
  var job = ko.dataFor(this);
  job.selected(!job.selected());
});

//// Load all the data
var framework = new framework.Framework({modelDict: {}});
$(document).one('loaded.jobs', function() {
  framework.load();
  connectors.fetchConnectors();
  connections.fetchConnections();
  submissions.fetchSubmissions();
});
jobs.fetchJobs();


//// Routes
$(document).ready(function () {
  window.location.hash = 'jobs';
  routie({
    "error": function() {
      showMainSection("sqoop-error");
      routie.removeAll();
    },
    "jobs": function() {
      showSection("jobs", "jobs-list");
    },
    "job/edit": function() {
      if (!viewModel.job()) {
        routie('jobs');
      }
      showSection("jobs", "job-editor");
    },
    "job/edit/:id": function(id) {
      viewModel.chooseJobById(id);
      routie('job/edit');
    },
    "job/new": function() {
      viewModel.newJob();
      routie('job/edit');
    },
    "job/save": function() {
      viewModel.saveJob();
      $(document).one('saved.job', function(){
        routie('jobs');
      });
    },
    "job/run": function() {
      if (viewModel.job()) {
        viewModel.job().start();
      }
      routie('jobs');
    },
    "job/run/:id": function(id) {
      viewModel.chooseJobById(id);
      routie('job/run');
    },
    "job/save-and-run": function() {
      viewModel.saveJob();
      $(document).one('saved.job', function(){
        routie('job/run');
      });
    },
    "job/stop": function() {
      if (viewModel.job()) {
        viewModel.job().stop();
      }
      routie('jobs');
    },
    "job/stop/:id": function(id) {
      viewModel.chooseJobById(id);
      routie('job/stop');
    },
    "job/status": function() {
      showSection("jobs", "job-status");
    },
    "job/status/:id": function(id) {
      viewModel.chooseJobById(id);
      routie('job/status');
    },
    "job/copy": function() {
      if (viewModel.job()) {
        viewModel.job().clone();
        $(document).one('cloned.job', function(){
          routie('jobs');
        });
      } else {
        routie('jobs');
      }
    },
    "job/copy/:id": function(id) {
      viewModel.chooseJobById(id);
      routie('job/copy');
    },
    "job/delete": function() {
      if (viewModel.job()) {
        viewModel.job().delete();
      } else {
        routie('jobs');
      }
      $(document).one('deleted.job', function(){routie('jobs');});
    },
    "job/delete/:id": function(id) {
      viewModel.chooseJobById(id);
      routie('job/delete');
    },
    "connection/edit": function() {
      showSection("jobs", "connection-editor");
    },
    "connection/edit/:id": function(id) {
      viewModel.chooseConnectionById(id);
      showSection("jobs", "connection-editor");
    },
    "connection/edit-cancel": function() {
      if (!viewModel.connection().persisted()) {
        viewModel.connections.pop();
      }
      routie('job/edit');
    },
    "connection/new": function() {
      viewModel.newConnection();
      routie('connection/edit');
    },
    "connection/save": function() {
      viewModel.saveConnection();
      $(document).one('saved.connection', function(){
        routie('job/edit');
      });
    },
    "connection/copy": function() {
      if (viewModel.connection()) {
        viewModel.connection().clone();
        $(document).one('cloned.connection', function(){
          routie('job/edit');
        });
      } else {
        routie('job/edit');
      }
    },
    "connection/delete": function() {
      if (viewModel.connection()) {
        viewModel.connection().delete();
        $(document).one('deleted.connection', function(){
          routie('job/edit');
        });
      } else {
        routie('job/edit');
      }
    }
  });
});
</script>

${ commonfooter(messages) | n,unicode }
