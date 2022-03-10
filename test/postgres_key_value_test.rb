# frozen_string_literal: true

require 'pg'
require 'test_helper'

class PostgresKeyValueTest < Minitest::Test
  def setup
    maint_connection = connection(db_name: 'postgres')
    db_exists = maint_connection.exec("SELECT 1 FROM pg_database WHERE datname = '#{db_name}'").nfields
    maint_connection.exec("CREATE DATABASE #{db_name}") unless db_exists

    connection.exec("DROP TABLE IF EXISTS #{db_table}")
    connection.exec("CREATE TABLE IF NOT EXISTS #{db_table} (key VARCHAR PRIMARY KEY, value json)")

    super
  end

  def test_that_it_has_a_version_number
    refute_nil ::PostgresKeyValue::VERSION
  end

  def test_it_should_write_and_read_strings
    subject['nl'] = 'Nederland'
    assert_equal('Nederland', subject['nl'])
  end

  def test_it_persists_over_instances
    subject['nl'] = 'Nederland'

    beta = ::PostgresKeyValue::Store.new(connection, db_table)
    assert_equal('Nederland', beta['nl'])
  end

  private

  def subject
    @subject ||= ::PostgresKeyValue::Store.new(connection, db_table)
  end

  def connection(db_name: ENV.fetch('DB_NAME'))
    connections[db_name] = PG.connect(
      user: db_user,
      password: db_password,
      host: db_host,
      port: db_port,
      dbname: db_name
    )
  end

  def connections
    @connections ||= {}
  end

  def db_table
    'kv_store'
  end

  def db_name
    ENV.fetch('DB_NAME')
  end

  def db_user
    ENV.fetch('DB_USER')
  end

  def db_password
    ENV.fetch('DB_PASSWORD')
  end

  def db_host
    ENV.fetch('DB_HOST')
  end

  def db_port
    ENV.fetch('DB_PORT')
  end
end
