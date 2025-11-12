module Privy
  class ListObject
    attr_reader :data, :has_more, :url

    def initialize(attributes = {})
      @data = Array(attributes[:data] || attributes['data'] || [])
      @has_more = attributes[:has_more] || attributes['has_more']
      @url = attributes[:url] || attributes['url']
    end

    # Delegate array methods to @data
    def [](index)
      @data[index]
    end

    def each(&block)
      return enum_for(:each) unless block_given?
      @data.each(&block)
    end

    def each_with_index(&block)
      return enum_for(:each_with_index) unless block_given?
      @data.each_with_index(&block)
    end

    def length
      @data.length
    end
    alias_method :size, :length

    def empty?
      @data.empty?
    end

    def first
      @data.first
    end

    def last
      @data.last
    end
  end
end