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

import logging

from django.db import connections, transaction

from beeswax.server.dbms import DataTable, BeeswaxClientInterface


LOG = logging.getLogger(__name__)


class BaseRDBMSDataTable(DataTable):
  def __init__(self, cursor, columns, fetch_size=1000):
    self.cursor = cursor
    self.columns = columns
    self.next = None
    self.startRowOffset = 0
    self.fetchSize = 1000

  @property
  def ready(self):
    return True

  @property
  def has_more(self):
    if not self.next:
      self.next = list(self.cursor.fetchmany(self.fetchSize))
    return bool(self.next)

  def rows(self):
    while self.has_more:
      yield self.next.pop(0)



class BaseRDBMSResult:
  def __init__(self, data_table):
    self.data_table = data_table
    self.rows = data_table.rows
    self.has_more = data_table.has_more
    self.start_row = data_table.startRowOffset
    self.columns = data_table.columns
    self.ready = True


class BaseRDMSClient(BeeswaxClientInterface):
  """Same API as Beeswax"""

  data_table_cls = None
  result_cls = None

  def __init__(self, query_server, user):
    self.user = user
    self.query_server = query_server


  def create_result(self, datatable):
    return self.result_cls(datatable)


  def query(self, query, statement=0):
    return self.execute_statement(query.get_query_statement(statement))


  def execute_statement(self, statement):
    cursor = connections[self.query_server['alias']].cursor()
    cursor.execute(statement, [])
    transaction.commit_unless_managed(using=self.query_server['alias'])
    if cursor.description:
      columns = [column[0] for column in cursor.description]
    else:
      columns = []
    return self.data_table_cls(cursor, columns)


  def dump_config(self):
    raise NotImplementedError()


  def get_log(self, handle):
    raise NotImplementedError()


  def get_databases(self):
    cursor = connections[self.query_server['alias']].cursor()
    cursor.execute("SHOW DATABASES", [])
    transaction.commit_unless_managed(using=self.query_server['alias'])
    return [row[0] for row in cursor.fetchall()]


  def get_tables(self, database, table_names):
    cursor = connections[self.query_server['alias']].cursor()
    cursor.execute("SHOW TABLES", [])
    transaction.commit_unless_managed(using=self.query_server['alias'])
    return [row[0] for row in cursor.fetchall()]


  def get_default_configuration(self, *args, **kwargs):
    return {}


  def get_columns(self, database, table):
    cursor = connections[self.query_server['alias']].cursor()
    cursor.execute("SHOW COLUMNS %s.%s" % (database, table), [])
    transaction.commit_unless_managed(using=self.query_server['alias'])
    return [row[0] for row in cursor.fetchall()]