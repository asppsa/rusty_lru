require 'rusty_lru/version'
require 'rutie'

# Top-level docs here
module RustyLRU

  # Loads Rust code
  Rutie.new(:rusty_lru).init 'Init_rusty_lru', __dir__

  # Now load the additional methods
  require_relative './rusty_lru/cache.rb'
end
