# frozen_string_literal: true

require 'pg'
require 'test_helper'
require 'postgres_key_value/utils'

class UtilsTest < DatabaseTest
  def test_create_table_creates_table
    # Undo the tables that were created in DatabaseTest#setup
    connection.exec("DROP TABLE IF EXISTS #{db_table}")

    TestMigration.new.create_table('kv_store')

    res = connection.exec("SELECT * FROM pg_catalog.pg_tables\
                           WHERE schemaname != 'pg_catalog' AND schemaname != 'information_schema'")
    assert_includes(res.field_values('tablename'), db_table)
  end

  def test_drop_table_removes_table
    # Ensure we have a table, avoid false positives from failing setup
    table_exists = connection
                   .exec_params('SELECT 1 FROM pg_catalog.pg_tables WHERE tablename = $1', [db_table])
                   .nfields
    assert_equal(1, table_exists)

    TestMigration.new.drop_table('kv_store')

    res = connection.exec("SELECT * FROM pg_catalog.pg_tables\
                           WHERE schemaname != 'pg_catalog' AND schemaname != 'information_schema'")
    refute_includes(res.field_values('tablename'), db_table)
  end

  def test_utils_requires_a_maintainance_connection_method
    assert_raises(NotImplementedError) do
      WrongTestMigration.new.create_table('kv_store')
    end
  end

  def test_database_maintainance_connection_connects_to_postgres_database
    pool = PostgresKeyValue::Utils::DatabaseConnections.new
    assert_kind_of(PG::Connection, pool.maintainance_connection)
    assert_equal('postgres', pool.maintainance_connection.db)
  end

  def test_database_connection_connects_to_any_database
    pool = PostgresKeyValue::Utils::DatabaseConnections.new
    assert_kind_of(PG::Connection, pool.connection(db_name: ENV.fetch('DB_NAME')))
  end

  def test_database_connection_closes_all_connection
    pool = PostgresKeyValue::Utils::DatabaseConnections.new
    pool.maintainance_connection
    pool.connection(db_name: ENV.fetch('DB_NAME'))
    pool.close_all
    assert_raises(PG::ConnectionBad) do
      pool.maintainance_connection.exec('SELECT VERSION()')
    end
  end

  ##
  # Example usage of Utils, used to test the module.
  class TestMigration
    include PostgresKeyValue::Utils

    # A realistic migration would probably define up() and down() here,
    # which then calls the Utils methods

    private

    def maintainance_connection
      connections_pool.connection(db_name: ENV.fetch('DB_NAME'))
    end

    def connections_pool
      @connections_pool ||= DatabaseConnections.new
    end
  end

  ##
  # Example usage of Utils, but without implementing required method
  class WrongTestMigration
    include PostgresKeyValue::Utils
  end
end
