require 'spec_helper'

require 'serf/errors/load_failure'
require 'serf/loader/loader'

describe Serf::Loader::Loader do
  let(:root_library_path) {
    File.join(File.dirname(__FILE__), '../../..')
  }

  context '#serfup Serf Map' do
    let(:random_message) {
      FactoryGirl.create :random_hash
    }
    subject {
      Serf::Loader::Loader.new.serfup(
        globs: [
          'example/components/**/*.serf',
          'example/serfs/**/*.serf'
        ],
        serfs: [
          'subsystem/requests/create_widget'
        ],
        base_path: root_library_path,
        env: {
          success_message: random_message
        })
    }

    it 'loads the Serfs into a frozen Serf Map' do
      expect(subject.frozen?).to be_true
    end

    it 'loads our only serf into the map' do
      expect(subject.size).to eq(1)
    end

    it 'gives us a proper callable serf' do
      serf = subject['subsystem/requests/create_widget']
      expect(subject).to_not be_nil

      results = serf.call({})
      expect(results).to_not be_nil
      expect(results.kind).to_not eq('serf/events/caught_error')
    end

    it 'returns nil on not found parcel kind' do
      expect(subject[nil]).to be_nil
    end

    it 'passes in a good environment' do
      serf = subject['subsystem/requests/create_widget']
      results = serf.call({})
      expect(results.kind).to eq('subsystem/events/mywidget_created')
      expect(results.message.success_message).to eq(random_message)
    end
  end

  context '#serfup Serf Map with missing Serf' do
    let(:serfup_config) {
      Hashie::Mash.new(
        globs: [],
        serfs: [
          'subsystem/requests/create_widget'
        ])
    }

    it 'raises an error' do
      expect {
        Serf::Loader::Loader.new.serfup serfup_config
      }.to raise_error('Missing Serf: subsystem/requests/create_widget')
    end
  end

  context '#serfup with construction error' do
    let(:serfup_config) {
      Hashie::Mash.new(
        globs: [
          'spec/data/construction_error.serf'
        ],
        serfs: [
          'spec/data/bad_construction'
        ])
    }

    it 'raises an error' do
      expect {
        Serf::Loader::Loader.new.serfup serfup_config
      }.to raise_error { |error|
        expect(error).to be_a(Serf::Errors::LoadFailure)
        expect(error.message).to match(/Kind: .+$/)
      }
    end
  end

  context '#serfup Serf Map bad serf file' do
    let(:serfup_config) {
      Hashie::Mash.new(
        globs: [
          'spec/data/raises_error.serf'
        ],
        serfs: [])
    }

    it 'raises an error' do
      expect {
        Serf::Loader::Loader.new.serfup serfup_config
      }.to raise_error { |error|
        expect(error).to be_a(Serf::Errors::LoadFailure)
        expect(error.message).to match(/^File: .+$/)
      }
    end
  end

end
