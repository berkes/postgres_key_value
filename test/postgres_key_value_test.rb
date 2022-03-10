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

  def test_it_updates_existing_keys
    subject['nl'] = 'Nederland'
    subject['nl'] = 'The Netherlands'
    assert_equal('The Netherlands', subject['nl'])
  end

  def test_it_handles_any_string_keys
    arr = %i[one two]
    subject[arr.to_s] = 'some value'

    assert_equal('some value', subject['[:one, :two]'])
  end

  def test_it_handles_symbol_keys
    subject[:key] = 'some value'
    assert_equal('some value', subject[:key])
  end

  def test_it_fails_on_setting_with_non_string_key
    assert_raises(PostgresKeyValue::InvalidKey) { subject[nil] = 'some value' }
    assert_raises(PostgresKeyValue::InvalidKey) { subject[42] = 'some value' }
  end

  def test_it_fails_on_getting_with_non_string_key
    assert_raises(PostgresKeyValue::InvalidKey) { subject[nil] }
    assert_raises(PostgresKeyValue::InvalidKey) { subject[42] }
  end

  def test_it_fails_on_setting_with_too_long_key
    # 10485760 is the max for a varchar by default
    key = 'k' * 10_485_760
    assert_raises(PostgresKeyValue::KeyLimitExceeded) do
      subject[key] = 'some value'
    end
  end

  def test_it_allows_getting_with_too_long_key
    key = 'k' * 10_485_760
    subject[key]
  end

  # TODO: if someone knows a reproducible *value*, which becomes a SQL injection
  # after .to_json, please let me know so I can write a test for that!
  def test_it_handles_bobby_tables_keys_on_writing
    key = "beta', '\"b\"'), ('gamma"
    subject[key] = 'beta'
    assert_equal(subject['beta'], nil)
    assert_equal(subject['gamma'], nil)
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
