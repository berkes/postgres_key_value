# frozen_string_literal: true

require 'test_helper'
require 'postgres_key_value/errors'
require 'postgres_key_value/store'

class StoreTest < DatabaseTest
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

  def test_it_returns_default_value_on_missing_key
    subject_with_default = ::PostgresKeyValue::Store.new(connection, db_table, 'missing')
    assert_equal('missing', subject_with_default['404'])
  end

  # TODO: if someone knows a reproducible *value*, which becomes a SQL injection
  # after .to_json, please let me know so I can write a test for that!
  def test_it_handles_bobby_tables_keys_on_writing
    key = "beta', '\"b\"'), ('gamma"
    subject[key] = 'beta'
    assert_nil(subject['beta'])
    assert_nil(subject['gamma'])
  end

  private

  def subject
    @subject ||= ::PostgresKeyValue::Store.new(connection, db_table)
  end
end
