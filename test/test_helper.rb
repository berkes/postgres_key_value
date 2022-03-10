# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'postgres_key_value'
require 'minitest/autorun'
require 'dotenv'
Dotenv.load
