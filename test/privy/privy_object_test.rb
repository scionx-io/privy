# frozen_string_literal: true

require 'test_helper'

module Privy
  class PrivyObjectTest < Minitest::Test
    def test_initialize_with_hash
      obj = Util::PrivyObject.new({ 'name' => 'Alice', 'age' => 30 })
      assert_equal 'Alice', obj['name']
      assert_equal 30, obj['age']
    end

    def test_bracket_access_string_key
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

    def test_method_access_mixed_keys
      obj = Util::PrivyObject.new({ 'string_key' => 1, symbol_key: 2 })
      assert_equal 1, obj.string_key
      assert_equal 2, obj.symbol_key
    end

    def test_bracket_setter
      obj = Util::PrivyObject.new({})
      obj['name'] = 'Bob'
      assert_equal 'Bob', obj['name']
    end

    def test_method_setter
      obj = Util::PrivyObject.new({})
      obj.name = 'Charlie'
      assert_equal 'Charlie', obj.name
      assert_equal 'Charlie', obj['name']
    end

    def test_to_hash
      data = { 'name' => 'Alice', 'age' => 30 }
      obj = Util::PrivyObject.new(data)

      assert_equal data, obj.to_hash
      assert_equal data, obj.to_h
    end

    def test_to_json
      obj = Util::PrivyObject.new({ 'balance' => 100, 'currency' => 'USD' })
      json = obj.to_json

      assert_instance_of String, json
      assert_includes json, '"balance"'
      assert_includes json, '100'
      assert_includes json, '"currency"'
      assert_includes json, '"USD"'
    end

    def test_to_s_returns_json
      obj = Util::PrivyObject.new({ 'balance' => 100 })
      string = obj.to_s

      assert_instance_of String, string
      assert_includes string, 'balance'
    end

    def test_keys
      obj = Util::PrivyObject.new({ 'name' => 'Alice', 'age' => 30 })
      keys = obj.keys

      assert_equal 2, keys.length
      assert_includes keys, 'name'
      assert_includes keys, 'age'
    end

    def test_values
      obj = Util::PrivyObject.new({ 'name' => 'Alice', 'age' => 30 })
      values = obj.values

      assert_equal 2, values.length
      assert_includes values, 'Alice'
      assert_includes values, 30
    end

    def test_key_check_string
      obj = Util::PrivyObject.new({ 'balance' => 100 })

      assert obj.key?('balance')
      refute obj.key?('missing')
    end

    def test_key_check_symbol
      obj = Util::PrivyObject.new({ balance: 100 })

      assert obj.key?(:balance)
      assert obj.key?('balance')  # Should work with string too
    end

    def test_inspect_format
      obj = Util::PrivyObject.new({ 'name' => 'Alice' })
      inspected = obj.inspect

      assert_match(/PrivyObject:0x[0-9a-f]+/, inspected)
      assert_includes inspected, 'name'
      assert_includes inspected, 'Alice'
    end

    def test_enumerable_each
      obj = Util::PrivyObject.new({ 'a' => 1, 'b' => 2, 'c' => 3 })
      result = {}

      obj.each { |k, v| result[k] = v }

      assert_equal({ 'a' => 1, 'b' => 2, 'c' => 3 }, result)
    end

    def test_enumerable_map
      obj = Util::PrivyObject.new({ 'a' => 1, 'b' => 2 })
      result = obj.map { |k, v| [k.upcase, v * 2] }

      assert_equal([['A', 2], ['B', 4]], result)
    end

    def test_enumerable_select
      obj = Util::PrivyObject.new({ 'a' => 1, 'b' => 2, 'c' => 3 })
      result = obj.select { |_k, v| v > 1 }

      assert_equal({ 'b' => 2, 'c' => 3 }, result.to_h)
    end

    def test_enumerable_count
      obj = Util::PrivyObject.new({ 'a' => 1, 'b' => 2, 'c' => 3 })

      assert_equal 3, obj.count
    end

    def test_nested_hash_access
      obj = Util::PrivyObject.new({
        'user' => { 'name' => 'Alice', 'age' => 30 },
        'balance' => 100
      })

      # Nested hashes should remain as hashes (not auto-converted to PrivyObject)
      # unless explicitly requested
      assert_instance_of Hash, obj['user']
      assert_equal 'Alice', obj['user']['name']
    end

    def test_array_values
      obj = Util::PrivyObject.new({
        'balances' => [
          { 'currency' => 'USD', 'amount' => 100 },
          { 'currency' => 'EUR', 'amount' => 85 }
        ]
      })

      assert_instance_of Array, obj['balances']
      assert_equal 2, obj['balances'].length
      assert_equal 'USD', obj['balances'][0]['currency']
    end

    def test_respond_to_missing
      obj = Util::PrivyObject.new({ 'balance' => 100 })

      assert obj.respond_to?(:balance)
      refute obj.respond_to?(:missing_method)
    end

    def test_method_missing_raises_for_unknown
      obj = Util::PrivyObject.new({})

      assert_raises(NoMethodError) do
        obj.nonexistent_method
      end
    end

    def test_enumerable_any
      obj = Util::PrivyObject.new({ 'a' => 1, 'b' => 2 })

      assert obj.any? { |_k, v| v == 2 }
      refute obj.any? { |_k, v| v == 99 }
    end

    def test_enumerable_find
      obj = Util::PrivyObject.new({ 'a' => 1, 'b' => 2, 'c' => 3 })
      result = obj.find { |_k, v| v == 2 }

      assert_equal ['b', 2], result
    end

    def test_nil_values
      obj = Util::PrivyObject.new({ 'value' => nil })

      assert_nil obj['value']
      assert_nil obj.value
    end

    def test_empty_object
      obj = Util::PrivyObject.new({})

      assert_equal 0, obj.count
      assert_equal [], obj.keys
      assert_equal [], obj.values
    end

    def test_convert_to_privy_object_with_hash
      result = Util.convert_to_privy_object({ 'name' => 'Alice' })

      assert_instance_of Util::PrivyObject, result
      assert_equal 'Alice', result['name']
    end

    def test_convert_to_privy_object_with_array
      result = Util.convert_to_privy_object([
        { 'id' => 1 },
        { 'id' => 2 }
      ])

      assert_instance_of Array, result
      assert_equal 2, result.length
      assert_instance_of Util::PrivyObject, result[0]
      assert_equal 1, result[0]['id']
    end

    def test_convert_to_privy_object_with_string
      result = Util.convert_to_privy_object('plain string')

      assert_equal 'plain string', result
    end

    def test_convert_to_privy_object_with_nil
      result = Util.convert_to_privy_object(nil)

      assert_nil result
    end
  end
end