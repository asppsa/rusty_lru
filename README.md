# RustyLRU

[![Gem Version](https://badge.fury.io/rb/rusty_lru.svg)](https://badge.fury.io/rb/rusty_lru)
[![Build Status](https://travis-ci.org/asppsa/rusty_lru.svg?branch=master)](https://travis-ci.org/asppsa/rusty_lru)

This gem provides an [LRU
cache](https://en.wikipedia.org/wiki/Cache_replacement_policies#Least_recently_used_(LRU))
for Ruby.  It uses [Rutie](https://rubygems.org/gems/rutie) to wrap the
[Rust](https://rust-lang.org/) [lru](https://crates.io/crates/lru) crate.

From a Ruby perspective, the API is close to that of the `Hash` class.   It
differs in that it will never grow beyond a capped number of key-value pairs,
which makes it suitable to use as a cache.


## Installation

Make sure you have Rust installed.  Add this line to your application's
Gemfile:

```ruby
gem 'rusty_lru'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rusty_lru


## Usage
 
The key concept of an LRU cache is the LRU list, which is a list of all the
key-value pairs in the cache, ordered by how recently they are used.  When the
cache fills to capacity, the pair at the bottom of the list will be dropped
each time a new pair is added.  Accessing/updating an existing pair in the
cache moves it to the top of the list.

Comprehensive documentation is available online:

- [Latest release](https://rubydoc.info/gems/rusty_lru)
- [Bleeding edge](https://rubydoc.info/github/asppsa/rusty_lru/master)

For the impatient, here is an example of basic usage:

~~~ ruby
# Creates a cache with a cap of 1,000 entries.
cache = RustyLRU::Cache.new(1000)

# Returns true iff the cache is empty.
cache.empty? #=> true

# Returns the number of pairs in the cache (not the cap).
cache.size #=> 0

# Adds a key-value pair to the cache.
cache['x'] = :y
cache['y'] = proc { 'anything can go here' }
cache['z'] = {"x" => 1}
cache.size #=> 3

# Overwriting a key returns the old value.
cache['x'] = :q #=> :y

# Retrieves the least recently used key-value pair without updating the LRU
# list.
cache.lru_pair #=> ['x', :q]

# Returns true iff the key exists. Does not affect the LRU list.
cache.key?('x') #=> true
cache.key?(:test) #=> false

# Retrieves a value by key, updating the LRU list.
cache['x'] #=> :q
cache.lru_pair #=> ['y', #<Proc:...>]

# Retrieves and deletes the least recently used key-value pair.
cache.pop #=> ['y', #<Proc:...>]
cache.size #=> 2
cache.lru_pair #=> ['z', {"x" => 1}]

# Retrieves a value by key without updating LRU list.
cache.peek('z') #=> {"x" => 1}
cache.lru_pair #=> ['z', {"x" => 1}]

# Deletes a key-value pair, returning the deleted value.
cache.delete('x') #=> :q
cache.size #=> 1

# Deletes all pairs from the cache
cache.clear #=> nil

# Changes the cache's cap.  If necessary, elements will be deleted (in LRU
# order) to accommodate this.
cache.resize(1)
cache[:test1] = 'test1'
cache[:test2] = 'test2'
cache.size #=> 1

# includes Enumerable, so things like conversion to Array and Hash are simple:
cache.to_a
cache.to_h
cache.each_key { |k| cache[k] = 'replaced' }
~~~


## Development

For development, check out the repo and then run `bundle install` to install
development dependencies.  `bundle exec rake test` will run RSpec and Rust
tests.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).


## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/asppsa/rusty_lru.


## License

Licensed under the Apache License 2.0.
