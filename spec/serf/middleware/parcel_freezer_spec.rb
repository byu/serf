require 'spec_helper'

require 'serf/middleware/parcel_freezer'

describe Serf::Middleware::ParcelFreezer do

  describe '#call' do

    it 'freezes the parcel' do
      parcel = {}
      app = described_class.new proc { |parcel|
        expect(parcel.frozen?).to be_true
      }
      app.call parcel
      expect(parcel.frozen?).to be_true
    end

  end

end
