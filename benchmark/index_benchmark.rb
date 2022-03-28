# frozen_string_literal: true

require 'pg'
require 'benchmark_helper'
require 'benchmark'

##
# Benchmark tests to compare indexes and assure linearity remains throughout
# changes in code.
#
# We get a _pkey index from the Primary Key constraint by design in PG. And we
# rely on this constraint for the upsert logic, so we cannot  test inserts'
# performance characteristics without an index realistic.
class IndexBenchmark < Minitest::Benchmark
  include PostgresBMHelper
  THRESHOLD = 0.99

  def self.bench_range
    bench_exp 1, 10
  end

  def setup
    prepare_postgres

    @value = 'Hello World'
  end

  def bench_read_without_index
    n = bench_range.max
    insert_n(n)
    time_with_index = Benchmark.measure { read_n(n) }
    remove_pkey_constraint
    time_without_index = Benchmark.measure { read_n(n) }
    assert(time_with_index.real < time_without_index.real)
  end

  def bench_insert_with_index
    assert_performance_linear(THRESHOLD) do |n|
      insert_n(n)
    end
  end

  def bench_read_with_index
    insert_n(bench_range.max)
    assert_performance_linear(THRESHOLD) do |n|
      read_n(n)
    end
  end

  def bench_upsert_with_index
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

  def remove_pkey_constraint
    connection.exec("ALTER TABLE #{db_table} DROP CONSTRAINT #{db_table}_pkey")
  end

  def subject
    @subject ||= ::PostgresKeyValue::Store.new(connection, db_table)
  end

  def bench_range
    self.class.bench_range
  end
end
