# frozen_string_literal: true

module PostgresKeyValue
  ##
  # Utilities to generate the tables, indexes and databases for use with this gem
  module Utils
    def create_table(table_name)
      maintainance_connection.exec("CREATE TABLE #{table_name} (key VARCHAR PRIMARY KEY, value json)")
    end

    def drop_table(table_name)
      maintainance_connection.exec("DROP TABLE #{table_name}")
    end

    protected

    def maintainance_connection
      raise(
        NotImplementedError,
        'including class must implement maintainance_connection with CREATE/DROP table permissions'
      )
    end
  end
end
