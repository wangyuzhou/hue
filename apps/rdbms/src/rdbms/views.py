#!/usr/bin/env python
# Licensed to Cloudera, Inc. under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  Cloudera, Inc. licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import json
import logging

from django.http import HttpResponse
from django.utils.translation import ugettext as _
from django.core.urlresolvers import reverse

from desktop.context_processors import get_app_name
from desktop.lib.django_util import format_preserving_redirect, render

import beeswax.forms
import beeswax.design
import beeswax.management.commands.beeswax_install_examples

from beeswax import common, models
from beeswax.forms import QueryForm
from beeswax.design import SQLdesign
from beeswax.server import dbms
from beeswax.server.dbms import get_query_server_config
from beeswax.views import authorized_get_history, save_design, get_db_choices,\
                          safe_get_design, parse_query_context


LOG = logging.getLogger(__name__)


def index(request):
  return execute_query(request)


"""
Queries Views
"""

def execute_query(request, design_id=None):
  """
  View function for executing an arbitrary synchronously query.
  """
  error_message = None
  form = QueryForm()
  action = request.path
  log = None
  app_name = get_app_name(request)
  query_type = models.SavedQuery.TYPES_MAPPING[app_name]
  design = safe_get_design(request, query_type, design_id)
  databases = get_db_choices(request)

  if request.method == 'POST':
    form.bind(request.POST)
    form.query.fields['database'].choices = databases # Could not do it in the form

    to_submit = request.POST.has_key('button-submit')

    # Always validate the saveform, which will tell us whether it needs explicit saving
    if form.is_valid():
      to_save = form.saveform.cleaned_data['save']
      to_saveas = form.saveform.cleaned_data['saveas']

      if to_saveas and not design.is_auto:
        # Save As only affects a previously saved query
        design = design.clone()

      if to_submit or to_save or to_saveas:
        explicit_save = to_save or to_saveas
        if explicit_save:
          request.info(_('Query saved!'))
        design = save_design(request, form, query_type, design, explicit_save)

      if to_submit:
        query = SQLdesign(form, query_type=query_type)
        query_server = get_query_server_config(app_name)
        db = dbms.get(request.user, query_server)
        query_history = db.execute_query(query, design)
        query_history.last_state = models.QueryHistory.STATE.expired.index
        query_history.save()
        return format_preserving_redirect(request, reverse('rdbms:view_results', kwargs={'id': query_history.id, 'first_row': 0}), {})
  else:
    if design.id is not None:
      data = SQLdesign.loads(design.data).get_query_dict()
      form.bind(data)
      form.saveform.set_data(design.name, design.desc)
    else:
      # New design
      form.bind()
    form.query.fields['database'].choices = databases # Could not do it in the form

  if not databases:
    request.error(_('No databases are available. Permissions could be missing.'))

  return render('execute.mako', request, {
    'action': action,
    'design': design,
    'error_message': error_message,
    'form': form,
    'log': log,
    'autocomplete_base_url': reverse('rdbms:autocomplete', kwargs={}),
    'can_edit_name': design.id and not design.is_auto,
  })


def view_results(request, id, first_row=0):
  """
  Returns the view for the results of the QueryHistory with the given id.

  The query results MUST be ready.
  To display query results, one should always go through the watch_query view.
  If the result set has has_result_set=False, display an empty result.

  If ``first_row`` is 0, restarts (if necessary) the query read.  Otherwise, just
  spits out a warning if first_row doesn't match the servers conception.
  Multiple readers will produce a confusing interaction here, and that's known.

  It understands the ``context`` GET parameter. (See watch_query().)
  """
  first_row = long(first_row)
  results = type('Result', (object,), {
                'rows': 0,
                'columns': [],
                'has_more': False,
                'start_row': 0,
            })
  fetch_error = False
  error_message = ''
  log = ''
  app_name = get_app_name(request)

  query_history = authorized_get_history(request, id, must_exist=True)
  query_server = query_history.get_query_server_config()
  design = query_history.design.get_design()
  db = dbms.get(request.user, query_server)

  try:
    database = design.query.get('database', 'default')
    db.use(database)
    datatable = db.execute_and_wait(design)
    results = db.client.create_result(datatable)
    data = [row for row in datatable.rows()]
  except Exception, e:
    fetch_error = True
    error_message = str(e)
    data = []

  context_param = request.GET.get('context', '')
  query_context = parse_query_context(context_param)

  # To remove when Impala has start_over support
  download  = request.GET.get('download', '')

  # Retrieve query results or use empty result if no result set
  downloadable = False

  # Handle errors
  error = fetch_error

  context = {
    'error': error,
    'error_message': error_message,
    'query': query_history,
    'results': data,
    'expected_first_row': first_row,
    'log': log,
    'hadoop_jobs': None,
    'query_context': query_context,
    'can_save': False,
    'context_param': context_param,
    'expired': True,
    'app_name': app_name,
    'download': download,
    'next_json_set': None
  }

  if not error:
    download_urls = {}
    if downloadable:
      for format in common.DL_FORMATS:
        download_urls[format] = reverse(app_name + ':download', kwargs=dict(id=str(id), format=format))

    save_form = beeswax.forms.SaveResultsForm()
    results.start_row = first_row

    context.update({
      'results': data,
      'has_more': results.has_more,
      'next_row': results.start_row + len(data),
      'start_row': results.start_row,
      'expected_first_row': first_row,
      'columns': results.columns,
      'download_urls': download_urls,
      'save_form': save_form,
      'can_save': query_history.owner == request.user and not download,
      'next_json_set': reverse('rdbms:view_results', kwargs={
        'id': str(id),
        'first_row': results.start_row + len(data)
      }) + ('?context=' + context_param or '') + '&format=json'
    })

  if request.GET.get('format') == 'json':
    context = {
      'results': data,
      'has_more': results.has_more,
      'next_row': results.start_row + len(data),
      'start_row': results.start_row,
      'next_json_set': reverse('rdbms:view_results', kwargs={
        'id': str(id),
        'first_row': results.start_row + len(data)
      }) + ('?context=' + context_param or '') + '&format=json'
    }
    return HttpResponse(json.dumps(context), mimetype="application/json")

  return render('wait_results.mako', request, context)
