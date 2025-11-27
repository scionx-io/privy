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
  end
end