# frozen_string_literal: true

require "pg"
require "test_helper"

class PostgresKeyValueTest < Minitest::Test
  def setup
    exists = connection.exec("SELECT 1 FROM pg_database WHERE datname = '#{db_name}'").nfields
    connection.exec("CREATE DATABASE #{db_name}") unless exists
    super
  end

  def test_that_it_has_a_version_number
    refute_nil ::PostgresKeyValue::VERSION
  end

  private

  def connection
    @connection ||= PG.connect(
      user: db_user,
      password: db_password,
      host: db_host,
      port: db_port,
    )
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
