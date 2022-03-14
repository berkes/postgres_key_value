# frozen_string_literal: true

module PostgresKeyValue
  class Error < StandardError; end
  class KeyLimitExceeded < StandardError; end
  class InvalidKey < StandardError; end
end
