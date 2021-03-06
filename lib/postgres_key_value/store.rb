# frozen_string_literal: true

module PostgresKeyValue
  ##
  # Interact with the Key Value Store
  class Store
    def initialize(connection, table, default = nil, &block)
      @connection = connection
      @table = table

      @default = default
      @block = block_given? ? block : nil
      raise ArgumentError, 'cannot provide both default value and default block' if @default && @block
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
      return instance_default(key) if res.num_tuples.zero?

      val = res.getvalue(0, 0)
      JSON.parse(val)
    end

    def key?(key)
      assert_correct_key(key)
      connection.exec_params(exists_q, [key]).num_tuples.positive?
    end

    def fetch(key, default = nil)
      assert_correct_key(key)
      res = connection.exec_params(read_q, [key])

      if res.num_tuples.zero?
        return default if default

        raise KeyError, "key not found: \"#{key}\""
      end

      val = res.getvalue(0, 0)
      JSON.parse(val)
    end

    def delete(key)
      assert_correct_key(key)
      res = connection.exec_params(delete_q, [key])
      return nil if res.num_tuples.zero?

      val = res.getvalue(0, 0)
      JSON.parse(val)
    end

    private

    def instance_default(key)
      if @block
        @block.call(key)
      else
        @default
      end
    end

    def assert_correct_key(key)
      return true if key.is_a?(String) || key.is_a?(Symbol)

      raise InvalidKey
    end

    def read_q
      "SELECT value FROM #{table} WHERE key = $1::text"
    end

    def exists_q
      "SELECT 1 FROM #{table} WHERE key = $1::text LIMIT 1"
    end

    def upsert_q
      "INSERT INTO #{table} (key, value) VALUES($1::text, $2::json) ON CONFLICT (key) DO UPDATE SET value = $2::json"
    end

    def delete_q
      "DELETE FROM #{table} WHERE key = $1::text RETURNING value"
    end

    attr_reader :connection, :table
  end
end
