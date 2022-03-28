# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'postgres_key_value'
require 'minitest/autorun'
require 'minitest/benchmark'
require 'dotenv'
Dotenv.load

require 'postgres_key_value/utils'

##
# Prepares the database for benchmarking on request.
module PostgresBMHelper
  def prepare_postgres
    db_exists = (maintainance_connection.exec("SELECT 1 FROM pg_database WHERE datname = '#{db_name}'").nfields == 1)

    maint_connection.exec("CREATE DATABASE #{db_name}") unless db_exists
    connection.exec("DROP TABLE IF EXISTS #{db_table}")
    connection.exec("CREATE TABLE IF NOT EXISTS #{db_table} (key VARCHAR PRIMARY KEY, value json)")
  end

  private

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
