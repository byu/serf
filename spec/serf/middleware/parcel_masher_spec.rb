require 'spec_helper'

require 'hashie'

require 'serf/middleware/parcel_masher'

describe Serf::Middleware::ParcelMasher do

  describe '#call' do

    it 'should Hashie::Mash the parcel' do
      parcel = nil
      app = described_class.new proc { |parcel|
        parcel.should be_a_kind_of(Hashie::Mash)
      }
      app.call parcel
    end

    it 'should autocreate headers and message' do
      parcel = nil
      app = described_class.new proc { |parcel|
        parcel.headers.should be_a_kind_of(Hashie::Mash)
        parcel.message.should be_a_kind_of(Hashie::Mash)
      }
      app.call parcel
    end

  end

end
