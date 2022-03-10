# frozen_string_literal: true

require_relative 'postgres_key_value/version'
require_relative 'postgres_key_value/store'

module PostgresKeyValue
  class Error < StandardError; end
  class KeyLimitExceeded < StandardError; end
  class InvalidKey < StandardError; end
end
