require 'spec_helper'

require 'serf/middleware/parcel_freezer'

describe Serf::Middleware::ParcelFreezer do

  describe '#call' do

    it 'freezes the parcel' do
      parcel = {}
      app = described_class.new proc { |parcel|
        parcel.frozen?.should be_true
      }
      app.call parcel
      parcel.frozen?.should be_true
    end

  end

end
