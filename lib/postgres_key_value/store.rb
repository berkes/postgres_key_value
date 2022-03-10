# frozen_string_literal: true

module PostgresKeyValue
  ##
  # Interact with the Key Value Store
  class Store
    def initialize(connection, table)
      @connection = connection
      @table = table
    end

    def []=(key, value)
      assert_correct_key(key)
      connection.exec_params(upsert_q, [key, value.to_json])
    rescue PG::ProgramLimitExceeded
      raise KeyLimitExceeded
    end

    def [](key)
      assert_correct_key(key)
      res = connection.exec_params(read_q, [key])
      return if res.num_tuples.zero?

      val = res.getvalue(0, 0)
      JSON.parse(val)
    end

    private

    def assert_correct_key(key)
      return true if key.is_a?(String) || key.is_a?(Symbol)

      raise InvalidKey
    end

    def upsert_q
      "INSERT INTO #{table} (key, value) VALUES($1::text, $2::json) ON CONFLICT (key) DO UPDATE SET value = $2::json"
    end

    def read_q
      "SELECT value FROM #{table} where key = $1::text"
    end

    attr_reader :connection, :table
  end
end
