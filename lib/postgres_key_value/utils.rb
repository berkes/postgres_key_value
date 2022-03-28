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

    ##
    # A naive connection pool. More of a factory to quickly build connections
    # using ENV vars, really.
    class DatabaseConnections
      def maintainance_connection
        connection(db_name: 'postgres')
      end

      def connection(db_name:)
        connections[db_name] ||= PG.connect(
          user: db_user,
          password: db_password,
          host: db_host,
          port: db_port,
          dbname: db_name
        )
      end

      def close_all
        connections.values.reject(&:finished?).each(&:close)
      end

      def connections
        @connections ||= {}
      end

      def db_table
        'kv_store'
      end

      def db_name
        ENV.fetch('DB_NAME')
      end

      def db_user
        ENV.fetch('DB_USER')
      end

      def db_password
        ENV.fetch('DB_PASSWORD')
      end

      def db_host
        ENV.fetch('DB_HOST')
      end

      def db_port
        ENV.fetch('DB_PORT')
      end
    end
  end
end
