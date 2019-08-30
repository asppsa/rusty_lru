require 'forwardable'

module RustyLRU
  # This class implements an
  # {https://en.wikipedia.org/wiki/Cache_replacement_policies LRU Cache}.
  #
  # {RustyLRU::Cache} objects behave a lot like Ruby's {https://ruby-doc.org/core/Hash.html Hash}
  # class, but with the important difference that internally a list is
  # maintained of all keys in order from most recently used to least
  # recently used (LRU).
  #
  # Additionally, if the cache is capped (see
  # {#initialize}), then when the cache is full to capacity an operation that
  # adds a new key will cause the key-value pair at the bottom of the LRU list
  # (i.e. the least-recently-used pair) to be dropped from the cache.  This way
  # the cache never grows beyond a pre-determined size.
  #
  # To precent items from being dropped, some operations (notably {#[]} and
  # {#[]=} move the key to the front of the list.
  #
  # Like {https://ruby-doc.org/core/Hash.html Hash}, this class includes the
  # {https://ruby-doc.org/core/Enumerable.html Enumerable} module, so it
  # responds to a number of methods not listed here, such as #map, #reduce, #to_a,
  # #to_h, etc.
  #
  # Like a Hash, values can be any object whatsoever, and keys can be any
  # object that responds to #hash and #eql? correctly.
  class Cache
    # @!method initialize(cap=nil)
    #   Initializes a new cache object.
    #
    #   If no cap is specified, the cache will be uncapped.  A cap can be added
    #   later using {#resize}.
    #
    #   @example Create a LRU cache with no cap
    #     cache = RustyLRU::Cache.new
    #
    #   @example Create a LRU cache with a maximum of 100 items
    #     cache = RustyLRU::Cache.new(100)

    # @!method [](key)
    #   Retrieves a value from the cache by key, updating the LRU list.
    #
    #   @example Retrieve a value
    #     cache["x"] #=> "y"
    #
    #   @param key [Object] The key to look up in the cache.
    #   @return [Object, nil] The value corresponding to the key, or nil.

    # @!method []=(key, value)
    #   Stores a key-value pair in the cache, updating the LRU list.
    #
    #   The stored pair becomes the most recently used upon insertion/update.
    #
    #   @example Store a pair
    #     cache[:x] = "z"
    #     cache[:x] = "y" #=> "z"
    #
    #   @param key [Object] The key to store
    #   @param value [Object] The value to store
    #   @return [Object, nil] The previous value, or `nil`.

    # @!method delete(key)
    #   Deletes the key-value pair corresponding to the given key from the
    #   cache.
    #
    #   @example Store and delete a pair
    #     cache["key"] = :value
    #     cache.delete("key") #=> :value
    #
    #   @param key [Object] The key to delete
    #   @return [Object, nil] The corresponding value, or nil

    # @!method pop()
    #   Deletes and returns the least-recently used key-value pair.
    #
    #   @example Create a cache with two elements, pop the first one.
    #     cache = RustyLRU::cache.new
    #     cache[:a] = 1
    #     cache[:b] = 2
    #     cache.pop #=> [:a, 1]
    #
    #   @return [<(Object, Object)>, nil] The least-recently-used pair, or nil.

    # @!method peek(key)
    #   Retrieves a value from the cache by key without updating the LRU list.
    #
    #   This method is equivalent to {#[]}, except that the LRU list is not
    #   affected.
    #
    #   @example Peek into the cache
    #     cache[:x] = "y"
    #     cache.peek(:x) #=> "y"
    #
    #   @param key [Object] The key too look up
    #   @return [Object, nil] The corresponding value, or nil

    # @!method lru_pair()
    #   Returns the least-recently used pair without affecting the LRU list.
    #
    #   This method is similar to {#pop}, but does not mutate the cache.
    #
    #   @example Conditionally remove the LRU pair
    #     cache.pop if cache.peek_lru == [:x, :y]
    #
    #   @return [<(Object, Object)>, nil] The least-recently-used pair, or nil.

    # @!method empty?()
    #   Returns true iff the cache is empty.
    #
    #   @return [Boolean]

    # @!method has_key?(key)
    #   Returns true iff the given key is present.  Does not affect the LRU list.
    #
    #   @param key [Object] The key to test for.
    #   @return [Boolean]

    # @!method length()
    #   Returns the number of key-value pairs stored in the cache.
    #
    #   @return [Integer]

    # @!method resize(cap)
    #   Alters the store's cap.
    #
    #   @param cap [Integer] The new cap.
    #   @return [nil]

    # @!method clear()
    #   Removes all key-value pairs from the cache.
    #
    #   @return [nil]

    # @!method each_pair()
    #   @overload each_pair()
    #     Yields each key-value pair in the cache to the caller.
    #
    #     @example {#each_pair} with a block
    #       cache.each_pair do |key, value|
    #         puts "#{key} = #{value}"
    #       end
    #
    #     @yieldparam key [Object] each key
    #     @yieldparam value [Object] each value
    #     @return [self]
    #
    #   @overload each_pair()
    #     Returns an {https://ruby-doc.org/core/Enumerator.html Enumerator}
    #     that will enumerate all key-value pairs.
    #
    #     @example Get a hash of values to keys
    #       cache.each_pair.map { |key, value| [value, key }.to_h
    #
    #     @return [Enumerator]

    # @!method each_key()
    #   @overload each_key()
    #     Yields each key in the cache to the caller.
    #
    #     @yieldparam key [Object] each key
    #     @return [self]
    #
    #   @overload each_key()
    #     Returns an {https://ruby-doc.org/core/Enumerator.html Enumerator}
    #     that will enumerate the keys in the cache.
    #
    #     @return [Enumerator]

    # @!method each_value()
    #   @overload each_value()
    #     Yields each value in the cache to the caller.
    #
    #     @yieldparam value [Object] each value
    #     @return [self]
    #
    #   @overload each_value()
    #     Returns an {https://ruby-doc.org/core/Enumerator.html Enumerator} for
    #     enumerating the values in the cache.
    #
    #     @return [Enumerator]

    # @api private
    module EnumHelpers
      def each_pair
        block_given? ? super : enum_for(:each_pair) { size }
      end

      def each_key
        block_given? ? super : enum_for(:each_key) { size }
      end

      def each_value
        block_given? ? super : enum_for(:each_value) { size }
      end
    end

    prepend EnumHelpers
    extend Forwardable
    include Enumerable

    # @!method keys()
    #   Returns all keys in the cache as an array
    #
    #   @return [Array<Object>] All keys
    def_delegator :each_key, :to_a, :keys

    # @!method values()
    #   Returns all values in the cache as an array
    #
    #   @return [Array<Object>] All values
    def_delegator :each_value, :to_a, :values

    alias store []=
    alias key? has_key?
    alias member? has_key?
    alias size length
    alias each each_pair
  end
end
