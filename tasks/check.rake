namespace :check do
  desc 'Benchmark Rusty against lru_redux'
  task bench: 'cargo:build' do
    require 'benchmark'
    require 'lru_redux'
    require 'rusty_lru'

    rusty = RustyLRU::Cache.new(1_000)

    redux = LruRedux::Cache.new(1_000)
    redux_thread_safe = LruRedux::ThreadSafeCache.new(1_000)

    Benchmark.bmbm do |bm|
      bm.report 'RustyLRU::Cache' do
        1_000_000.times { rusty[rand(2_000)] = :value }
      end

      bm.report 'LruRedux::Cache' do
        1_000_000.times { redux[rand(2_000)] = :value }
      end

      bm.report 'LruRedux::ThreadSafeCache' do
        1_000_000.times { redux_thread_safe[rand(2_000)] = :value }
      end
    end
  end

  task mem: 'cargo:build' do
    require 'rusty_lru'
    require 'securerandom'

    rusty = RustyLRU::Cache.new(1_000_000)
    statm = File.open("/proc/#{Process.pid}/statm")

    loop do
      1_000_000.times { rusty[SecureRandom.random_bytes(100)] ||= SecureRandom.random_bytes(100) }
      p %i[size resident shared text lib data dt].zip(statm.read.split(' ').map(&:to_i)).to_h.slice(:size, :resident, :data)
      statm.rewind
    end
  end

  task threadsafe: 'cargo:build' do
    require 'rusty_lru'
    require 'securerandom'

    rusty = RustyLRU::Cache.new(1000)
    pairs = (0..100).map do |j|
      [j, SecureRandom.uuid]
    end

    pairs.map do |j, v|
      Thread.new do
        created_values = (0...100).map do
          # Each thread tries to create the same pair.  Only one should
          # succeed.
          Thread.new { rusty.create(j, v) }
        end.map(&:value)
      end
    end.map(&:value).each do |values|
      count = values.select(&:itself).size
      raise "#{j}: Got #{count}" unless count == 1
    end

    pairs.each do |k, v|
      p [k, v, rusty.delete(k) == v]
    end
  end
end
