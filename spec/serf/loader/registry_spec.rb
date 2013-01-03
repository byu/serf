require 'spec_helper'

require 'serf/loader/registry'

describe Serf::Loader::Registry do
  let(:random_message) {
    FactoryGirl.create :random_hash
  }

  context '#add' do
    it 'registers a named block, but does not call it' do
      uncalled_mock = double 'Uncalled Mock'
      expect(subject.blocks.size).to eq(0)
      expect(subject.values.size).to eq(0)
      subject.add 'component_name' do
        uncalled_mock
      end
      expect(subject.blocks.size).to eq(1)
      expect(subject.values.size).to eq(0)
    end
  end

  context '#[]' do
    it 'evaluates a block on lookup' do
      expect(subject.blocks.size).to eq(0)
      expect(subject.values.size).to eq(0)
      subject.add 'component_name' do
        random_message
      end
      expect(subject['component_name']).to eq(random_message)
      expect(subject.blocks.size).to eq(0)
      expect(subject.values.size).to eq(1)
    end

    it 'returns memoized block value' do
      call_once = double 'Callable'
      call_once.should_receive(:call).once.and_return(random_message)

      # Make the add to the registry
      expect(subject.blocks.size).to eq(0)
      expect(subject.values.size).to eq(0)
      subject.add 'component_name' do
        call_once.call
      end

      # First call
      expect(subject['component_name']).to eq(random_message)
      expect(subject.blocks.size).to eq(0)
      expect(subject.values.size).to eq(1)

      # This should be memoized
      expect(subject['component_name']).to eq(random_message)
      expect(subject.blocks.size).to eq(0)
      expect(subject.values.size).to eq(1)
    end

    it 'returns nil on not found' do
      expect(subject[random_message]).to be_nil
    end
  end

end
