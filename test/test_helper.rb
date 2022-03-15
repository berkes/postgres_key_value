# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'pg'

require 'dotenv'
Dotenv.load

require 'simplecov'
SimpleCov.start

require 'minitest/autorun'

class DatabaseConnections
  def maintainance_connection
    connection(db_name: 'postgres')
  end

  def connection(db_name:)
    connections[db_name] ||= PG.connect(
      user: db_user,
      password: db_password,
      host: db_host,
      port: db_port,
      dbname: db_name
    )
  end

  def close_all
    connections.values.reject(&:finished?).each(&:close)
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
    @connections_pool ||= DatabaseConnections.new
  end
end
