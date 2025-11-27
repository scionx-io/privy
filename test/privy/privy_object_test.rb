# frozen_string_literal: true

require_relative '../privy_test'
require 'minitest/autorun'

module Privy
  class PrivyObjectTest < Minitest::Test
    def test_initialize_with_attributes
      obj = Util::PrivyObject.new({ 'name' => 'Alice', 'age' => 30 })
      assert_equal 'Alice', obj['name']
      assert_equal 30, obj['age']
    end

    def test_bracket_access
      obj = Util::PrivyObject.new({ 'balance' => 100 })
      assert_equal 100, obj['balance']
    end

    def test_method_access_string_key
      obj = Util::PrivyObject.new({ 'balance' => 100 })
      assert_equal 100, obj.balance
    end

    def test_method_access_symbol_key
      obj = Util::PrivyObject.new({ balance: 200 })
      assert_equal 200, obj.balance
    end

    def test_setter_via_bracket
      obj = Util::PrivyObject.new({})
      obj['name'] = 'Bob'
      assert_equal 'Bob', obj['name']
    end

    def test_setter_via_method
      obj = Util::PrivyObject.new({})
      obj.name = 'Charlie'
      assert_equal 'Charlie', obj.name
    end

    def test_to_hash
      obj = Util::PrivyObject.new({ 'name' => 'Alice', 'age' => 30 })
      hash = obj.to_hash

      assert_instance_of Hash, hash
      assert_equal 'Alice', hash['name']
      assert_equal 30, hash['age']
    end

    def test_to_json
      obj = Util::PrivyObject.new({ 'balance' => 100 })
      json = obj.to_json

      assert_instance_of String, json
      assert_includes json, '"balance"'
      assert_includes json, '100'
    end

    def test_keys
      obj = Util::PrivyObject.new({ 'name' => 'Alice', 'age' => 30 })
      keys = obj.keys

      assert_equal ['name', 'age'].sort, keys.sort
    end

    def test_values
      obj = Util::PrivyObject.new({ 'name' => 'Alice', 'age' => 30 })
      values = obj.values

      assert_includes values, 'Alice'
      assert_includes values, 30
    end

    def test_inspect_format
      obj = Util::PrivyObject.new({ 'name' => 'Alice' })
      inspected = obj.inspect

      assert_match(/PrivyObject:0x[0-9a-f]+/, inspected)
      assert_includes inspected, 'name'
      assert_includes inspected, 'Alice'
    end

    def test_to_s_returns_json
      obj = Util::PrivyObject.new({ 'balance' => 100 })
      string = obj.to_s

      assert_instance_of String, string
      assert_includes string, 'balance'
    end
  end
end