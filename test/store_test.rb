# frozen_string_literal: true

require 'test_helper'
require 'postgres_key_value/errors'
require 'postgres_key_value/store'

##
# Test the main interface for PostgresKeyValue.
#
# rubocop:disable Metrics/ClassLength
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
    subject[%i[one two].to_s] = 'some value'
    assert_equal('some value', subject['[:one, :two]'])
  end

  def test_it_handles_symbol_keys
    subject[:key] = 'some value'
    assert_equal('some value', subject[:key])
  end

  def test_key_returns_true_if_key_exists
    subject['exists'] = 'value'
    assert(subject.key?('exists'))
  end

  def test_key_returns_false_if_key_doesnt_exist
    refute(subject.key?('exists'))
  end

  def test_key_returns_true_even_if_value_falsey
    subject['exists'] = nil
    assert(subject.key?('exists'))
  end

  def test_fetch_returns_value
    subject['exists'] = 'value'
    assert_equal('value', subject.fetch('exists'))
  end

  def test_fetch_provides_default
    assert_equal('not found', subject.fetch('404', 'not found'))
  end

  def test_fetch_fails_on_not_found_without_default
    assert_raises(KeyError) { subject.fetch('404') }
  end

  def test_fetch_fails_on_not_found_without_default_even_with_instance_default
    assert_raises(KeyError) { subject_with_default_value.fetch('404') }
  end

  def test_fetch_default_ignores_instance_default
    assert_equal('not found', subject_with_default_value.fetch('404', 'not found'))
  end

  def test_fetch_default_ignores_instance_default_block
    assert_equal('not found', subject_with_default_block.fetch('404', 'not found'))
  end

  def test_it_fails_on_setting_with_non_string_key
    assert_raises(PostgresKeyValue::InvalidKey) { subject[42] = 'some value' }
  end

  def test_it_deletes_by_key
    subject['nl'] = 'Netherlands'
    subject.delete('nl')

    assert_nil(subject['nl'])
    refute(subject.key?('nl'))
  end

  def test_it_returns_vaue_on_delete
    subject['nl'] = 'Netherlands'
    assert_equal('Netherlands', subject.delete('nl'))
  end

  def test_it_deletes_not_found_keys_silent
    assert_nil(subject.delete('not found'))
  end

  def test_it_fails_on_getting_with_non_string_key
    assert_raises(PostgresKeyValue::InvalidKey) { subject[42] }
  end

  def test_it_fails_on_key_with_non_string_key
    assert_raises(PostgresKeyValue::InvalidKey) { subject.key?(42) }
  end

  def test_it_fails_on_fetch_with_non_string_key
    assert_raises(PostgresKeyValue::InvalidKey) { subject.fetch(42) }
  end

  def test_it_fails_on_delete_with_non_string_key
    assert_raises(PostgresKeyValue::InvalidKey) { subject.delete(42) }
  end

  def test_it_fails_on_setting_with_too_long_key
    assert_raises(PostgresKeyValue::KeyLimitExceeded) { subject[long_key] = 'some value' }
  end

  def test_it_allows_getting_with_too_long_key
    subject[long_key]
  end

  def test_it_returns_default_value_on_missing_key
    assert_equal('missing', subject_with_default_value['404'])
  end

  def test_it_returns_from_block_on_missing_key
    assert_equal('404 is missing', subject_with_default_block['404'])
  end

  def test_it_fails_when_default_value_and_block_provided
    assert_raises(ArgumentError) do
      ::PostgresKeyValue::Store.new(connection, db_table, 'missing') { |key| "#{key} is missing" }
    end
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

  def long_key
    # 10485760 is the max for a varchar by default
    'k' * 10_485_760
  end

  def subject_with_default_block
    @subject_with_default_block ||= ::PostgresKeyValue::Store.new(connection, db_table) { |key| "#{key} is missing" }
  end

  def subject_with_default_value
    @subject_with_default_value ||= ::PostgresKeyValue::Store.new(connection, db_table, 'missing')
  end
end
# rubocop:enable all
