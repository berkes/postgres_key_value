# frozen_string_literal: true

require "test_helper"

class PostgresKeyValueTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::PostgresKeyValue::VERSION
  end
end
