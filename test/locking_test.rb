# frozen_string_literal: true

require 'test_helper'
require 'postgres_key_value/errors'
require 'postgres_key_value/store'

require 'byebug'
##
# Test and demonstrate the locking and transactional behaviour
class LockingTest < DatabaseTest
  # This will hang if threads close transactions or run queries on one
  # connection while another one is underway.
  def test_it_does_not_lock
    threads = []
    # Ready.. Set... Go!
    (1..10).each do |i|
      threads << Thread.new { new_subject[:one] = i }
    end
    # Assert all threads are finished
    threads.each(&:join)
    assert(threads.map(&:status).all? { |status| status == false })
  end

  def test_it_waits_for_a_transaction_to_commit_before_reading
    thread = Thread.new do
      one_connection = connection
      one_connection.transaction do |tx_conn|
        one_subject = ::PostgresKeyValue::Store.new(one_connection, db_config.db_table)
        Thread.stop
        one_subject[:nl] = 'Netherlands'
        # Make the database wait a little, to ensure the read-thread finishes first
        tx_conn.exec('SELECT pg_sleep(0.1)')
      end
    end

    other_connection = connection
    other_subject = ::PostgresKeyValue::Store.new(other_connection, db_config.db_table)

    # Align thread and main-thread (this) at the start-line. Ready, set.. go
    sleep(0.1) until thread.status == 'sleep'
    thread.run
    raced_val = other_subject[:nl]

    # And wait until all of us have crossed the finish -line
    thread.join(1)

    assert_nil(raced_val)
  end

  private

  # Don't memoize to avoid threads re-using the same connection
  def connection
    PG::Connection.open(
      user: db_config.db_user,
      password: db_config.db_password,
      host: db_config.db_host,
      port: db_config.db_port,
      dbname: db_config.db_name
    )
  end

  def db_config
    @db_config ||= DatabaseConnections.new
  end

  # Don't memoize to avoid threads re-using the same connection
  def new_subject
    ::PostgresKeyValue::Store.new(connection, db_config.db_table)
  end
end
