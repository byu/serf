require 'spec_helper'

require 'serf/loader'

describe Serf::Loader do
  let(:root_library_path) {
    File.join(File.dirname(__FILE__), '../..')
  }

  context '.serfup' do
    let(:random_message) {
      FactoryGirl.create :random_hash
    }
    subject {
      Serf::Loader.serfup(
        globs: [
          'example/**/*.serf'
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

end
