# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'pg'

require 'dotenv'
Dotenv.load

require 'simplecov'
SimpleCov.start

require 'minitest/autorun'

##
# A Test Class which runs test with the database enabled and prepared
class DatabaseTest < Minitest::Test
  def setup
    db_exists = maintainance_connection
                .exec("SELECT 1 FROM pg_database WHERE datname = '#{db_name}'").values.any?
    maintainance_connection.exec("CREATE DATABASE #{db_name}") unless db_exists

    # Surpress "notice X already exists" and similar errors from tainting test output
    connection.exec('SET client_min_messages = error')

    # Deliberate duplicated with PostgresKeyValue::Utils, because using that
    # here would make the tests for that class weird. We want this to be separate.
    connection.exec("DROP TABLE IF EXISTS #{db_table}")
    connection.exec("CREATE TABLE IF NOT EXISTS #{db_table} (key VARCHAR PRIMARY KEY, value json)")

    super
  end

  def teardown
    connections_pool.close_all
  end

  protected

  def maintainance_connection
    @maintainance_connection ||= connections_pool.maintainance_connection
  end

  def connection
    @connection ||= connections_pool.connection(db_name: db_name)
  end

  def db_table
    @connections_pool.db_table
  end

  def db_name
    @connections_pool.db_name
  end

  def connections_pool
    @connections_pool ||= PostgresKeyValue::Utils::DatabaseConnections.new
  end
end
