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
      connection.transaction do |transaction|
        sql = "INSERT INTO #{table} (key, value) VALUES('#{key}', '#{value.to_json}')"
        transaction.exec(sql)
      end
    end

    def [](key)
      res = connection.exec("SELECT value FROM #{table} WHERE key = '#{key}' LIMIT 1")
      val = res.getvalue(0, 0) if res.num_tuples.positive?
      JSON.parse(val)
    end

    private

    attr_reader :connection, :table
  end
end
