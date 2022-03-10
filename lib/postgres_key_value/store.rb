# frozen_string_literal: true

module PostgresKeyValue
  ##
  # Interact with the Key Value Store
  class Store
    def initialize(connection, table)
      @connection = connection
      @table = table

      @default = nil

      @fakehash = {}
    end

    def []=(key, value)
      assert_correct_key(key)
      connection.transaction do |transaction|
        sql = <<-SQL
          INSERT INTO #{table} (key, value) VALUES('#{key}', '#{value.to_json}')
          ON CONFLICT (key) DO UPDATE SET value = '#{value.to_json}'
        SQL
        transaction.exec(sql)
      end
    rescue PG::ProgramLimitExceeded
      raise KeyLimitExceeded
    end

    def [](key)
      assert_correct_key(key)
      res = connection.exec("SELECT value FROM #{table} WHERE key = '#{key}' LIMIT 1")
      return if res.num_tuples.zero?

      val = res.getvalue(0, 0)
      JSON.parse(val)
    end

    private

    def assert_correct_key(key)
      return true if key.is_a?(String) || key.is_a?(Symbol)

      raise InvalidKey
    end

    attr_reader :connection, :table
  end
end
