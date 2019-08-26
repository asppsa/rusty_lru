require 'forwardable'

module RustyLRU
  # Top-level
  class Cache
    # This module is prepended to add support for returning an enumerator when
    # a block is not given for each of {#each_pair}, {#each_key} and
    # {#each_value}.
    #
    # @private
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

    def_delegator :each_key, :to_a, :keys
    def_delegator :each_value, :to_a, :values

    alias store []=
    alias key? has_key?
    alias member? has_key?
    alias size length
    alias each each_pair
  end
end
