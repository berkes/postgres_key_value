# frozen_string_literal: true

require 'pg'
require 'benchmark_helper'

##
# Benchmark tests to compare indexes and assure linearity remains throughout
# changes in code.
class IndexBenchmark < Minitest::Benchmark
  THRESHOLD = 0.998

  def setup
    maint_connection = connection(db_name: 'postgres')
    db_exists = maint_connection.exec("SELECT 1 FROM pg_database WHERE datname = '#{db_name}'").nfields
    maint_connection.exec("CREATE DATABASE #{db_name}") unless db_exists

    connection.exec("DROP TABLE IF EXISTS #{db_table}")
    connection.exec("CREATE TABLE IF NOT EXISTS #{db_table} (key VARCHAR PRIMARY KEY, value json)")

    @value = 'Hello World'
  end

  def bench_insert_without_index
    assert_performance_linear(THRESHOLD) do |n|
      insert_n(n)
    end
  end

  def bench_read_without_index
    insert_n(bench_range.max)
    assert_performance_linear(THRESHOLD) do |n|
      read_n(n)
    end
  end

  def bench_insert_with_index
    connection.exec("CREATE UNIQUE INDEX key_index ON #{db_table} USING btree (key)")
    assert_performance_linear(THRESHOLD) do |n|
      insert_n(n)
    end
  end

  def bench_read_with_index
    connection.exec("CREATE UNIQUE INDEX key_index ON #{db_table} USING btree (key)")
    insert_n(bench_range.max)
    assert_performance_linear(THRESHOLD) do |n|
      read_n(n)
    end
  end

  def bench_upsert_without_index
    insert_n(bench_range.max)
    assert_performance_linear(THRESHOLD) do |n|
      insert_n(n)
    end
  end

  def bench_upsert_with_index
    connection.exec("CREATE UNIQUE INDEX key_index ON #{db_table} USING btree (key)")
    insert_n(bench_range.max)
    assert_performance_linear(THRESHOLD) do |n|
      insert_n(n)
    end
  end

  private

  attr_reader :value

  def insert_n(amount)
    amount.times do |index|
      subject[index.to_s] = value
    end
  end

  def read_n(amount)
    amount.times do |index|
      subject[index.to_s]
    end
  end

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

  def bench_range
    self.class.bench_range
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
