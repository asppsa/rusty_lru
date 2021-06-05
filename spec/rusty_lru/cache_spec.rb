RSpec.shared_examples 'a hash map' do
  describe '.new' do
    it 'constructs an instance' do
      expect(subject).to be_a described_class
    end
  end

  shared_examples 'length' do
    it 'is initially zero' do
      expect(subject.public_send(length)).to eq 0
    end

    it 'grows when objects are added' do
      expect((1..99).map do |i|
        subject[i] = i
        subject.public_send(length)
      end).to eq((1..99).to_a)
    end
  end

  describe '#size' do
    let(:length) { :size }

    include_examples 'length'
  end

  describe '#length' do
    let(:length) { :length }

    include_examples 'length'
  end

  describe '#[]=' do
    it 'adds key-value pairs' do
      expect { subject['X'] = 'Y' }
        .to change { subject['X'] }
        .from(nil)
        .to('Y')
    end

    it 'uses the key\'s #hash and #eql? methods' do
      key = double('key')
      expect(key).to receive(:hash).and_return(42)
      subject[key] = 'test'
      key2 = double('key2')
      expect(key2).to receive(:hash).and_return(42)
      expect(key2).to receive(:eql?).with(key).and_return(true)
      expect(subject[key2]).to eq 'test'
    end

    context 'when an key\'s #hash method raises an error' do
      it 'raises the exception' do
        key = double('key')
        expect(key).to receive(:hash).and_raise('specific error')
        expect { subject[key] = 'test' }.to raise_error 'specific error'
      end
    end

    context 'when a key\'s #hash method doesn\'t return a number' do
      it 'raises a TypeError' do
        key = double('key')
        expect(key).to receive(:hash).and_return('not a number')
        expect { subject[key] = 'test' }.to raise_error TypeError
      end
    end

    context 'when a key already exists' do
      before { subject['X'] = 'Y' }

      it 'overwrites the value' do
        expect { subject['X'] = 'Z' }
          .to change { subject['X'] }
          .from('Y')
          .to('Z')
      end

      it 'can set the value to nil' do
        expect { subject['X'] = nil }
          .to change { subject['X'] }
          .from('Y')
          .to(nil)
      end
    end
  end

  describe '#[]' do
    it 'returns the correpsonding value, or nil' do
      expect(subject['x']).to be_nil
      subject['x'] = 'y'
      expect(subject['x']).to eq 'y'
      expect(subject['y']).to be_nil
    end
  end

  describe '#delete' do
    before { subject['x'] = 1 }

    it 'removes items by key' do
      expect { subject.delete('x') }
        .to change(subject, :length)
        .from(1)
        .to(0)
    end

    it 'returns the value corresponding to the given key' do
      expect(subject.delete('x')).to eq 1
    end
  end

  describe '#empty?' do
    it 'is true iff there are no items' do
      expect { subject['x'] = 1 }
        .to change(subject, :empty?)
        .from(true)
        .to(false)

      expect { subject.delete('x') }
        .to change(subject, :empty?)
        .from(false)
        .to(true)
    end
  end

  describe '#clear' do
    before do
      99.times do |i|
        subject["x#{i}"] = "y#{i}"
      end
    end

    it 'removes all items' do
      expect { subject.clear }
        .to change { [subject.length, subject.empty?] }
        .from([99, false])
        .to([0, true])
    end
  end

  describe '#key?' do
    it 'returns true iff the key is present' do
      expect { subject['test'] = 'ok' }
        .to change { subject.key?('test') }
        .from(false)
        .to(true)
    end
  end

  shared_examples 'an enumerator' do
    let :pairs do
      (1..99).map { |i| ["x#{i}", "y#{i}"] }
    end

    before do
      pairs.each { |key, value| subject[key] = value }
    end

    context 'with a block' do
      it 'yields' do
        expect { |b| subject.public_send(each, &b) }.to yield_control
      end

      it 'returns self' do
        expect(subject.public_send(each) {}).to be subject
      end

      it 'yields each item' do
        subject.public_send each do |item|
          expect(items).to include(item)
          items.delete(item)
        end

        expect(items).to be_empty
      end
    end

    context 'without a block' do
      it 'returns an enumerator that enumerates the items' do
        enum = subject.public_send(each)
        expect(enum).to be_a Enumerator
        expect(enum.to_a).to contain_exactly(*items)
      end
    end
  end

  describe '#each_pair' do
    let(:each) { :each_pair }
    let(:items) { pairs }

    it_behaves_like 'an enumerator'
  end

  describe '#each_key' do
    let(:each) { :each_key }
    let(:items) { pairs.map(&:first) }

    it_behaves_like 'an enumerator'
  end

  describe '#each_value' do
    let(:each) { :each_value }
    let(:items) { pairs.map(&:last) }

    it_behaves_like 'an enumerator'
  end

  describe '#keys' do
    it 'returns all keys as an array' do
      99.times { |i| subject["key#{i}"] = 1 }
      expect(subject.keys).to contain_exactly(*(0...99).map { |i| "key#{i}" })
    end
  end

  describe '#values' do
    it 'returns all values as an array' do
      99.times { |i| subject[i] = "value#{i}" }
      expect(subject.values).to contain_exactly(*(0...99).map { |i| "value#{i}" })
    end
  end
end

RSpec.shared_examples 'an LRU cache' do
  describe '#lru_pair' do
    it 'returns the least recently used key/value pair' do
      99.times do |i|
        subject[{ i: i }] = i
      end

      expect(subject.lru_pair).to eq [{ i: 0 }, 0]

      # An update will change it
      expect { subject[{ i: 0 }] = 'test' }
        .to change(subject, :lru_pair)
        .from([{ i: 0 }, 0])
        .to([{ i: 1 }, 1])

      # A read will change it
      expect { subject[{ i: 1 }] }
        .to change(subject, :lru_pair)
        .from([{ i: 1 }, 1])
        .to([{ i: 2 }, 2])
    end

    it 'does not remove the pair' do
      subject['x'] = 'test'
      expect(subject.lru_pair).to eq(%w[x test])
      expect(subject['x']).to eq 'test'
    end
  end

  describe '#peek' do
    it 'returns the corresponding value without affecting its LRU status' do
      99.times do |i|
        subject[i] = i
      end

      99.times do |i|
        expect { subject.peek(i) }
          .not_to change(subject, :lru_pair)
          .from([0, 0])
      end
    end
  end

  describe '#pop' do
    it 'removes the least recently used key/value pair' do
      99.times do |i|
        subject[i] = i
      end

      expect(subject.pop).to eq([0, 0])
      subject[1]
      expect(subject.pop).to eq([2, 2])
      subject[4]
      subject[3]
      subject[5]
      expect(subject.pop).to eq([6, 6])
      expect(subject.length).to eq 96
    end
  end
end

RSpec.shared_examples 'a capped LRU cache' do |cap|
  context 'when full' do
    before do
      cap.times do |i|
        subject[i] = i
      end
    end

    it 'deletes least recently used items first' do
      expect { subject['test'] = 'test' }
        .to change { subject.key?(0) }
        .from(true)
        .to(false)

      subject[1]

      expect { subject['test2'] = 'test' }
        .to change { subject.key?(2) }
        .from(true)
        .to(false)

      expect(subject.size).to eq cap
    end

    describe '#resize' do
      context 'to a larger capacity' do
        before do
          subject.resize(cap + 2)
        end

        it 'creates extra space' do
          expect { subject['test'] = 'test' }
            .not_to change(subject, :lru_pair)
            .from([0, 0])
        end
      end

      context 'to a smaller capacity' do
        it 'deletes the least used items' do
          expect { subject.resize(cap - 2) }
            .to change(subject, :lru_pair)
            .from([0, 0])
            .to([2, 2])
        end
      end
    end
  end
end

RSpec.describe RustyLRU::Cache do
  describe 'with no cap' do
    subject { described_class.new }

    it_behaves_like 'a hash map'
    it_behaves_like 'an LRU cache'

    context 'when resized' do
      before { subject.resize(200) }

      it_behaves_like 'a capped LRU cache', 200
    end
  end

  describe 'with a cap' do
    subject { described_class.new(100) }

    it_behaves_like 'a hash map'
    it_behaves_like 'an LRU cache'
    it_behaves_like 'a capped LRU cache', 100

    context 'when resized' do
      before { subject.resize(200) }

      it_behaves_like 'a capped LRU cache', 200
    end
  end
end

# This is to ensure that the behaviour matches behaviours of Hash that we are
# interested in.
RSpec.describe Hash do
  subject { described_class.new }

  it_behaves_like 'a hash map'
end
