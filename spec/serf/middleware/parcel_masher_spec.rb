require 'spec_helper'

require 'hashie'

require 'serf/middleware/parcel_masher'

describe Serf::Middleware::ParcelMasher do

  describe '#call' do

    it 'makes Hashie::Mash of the parcel' do
      parcel = nil
      app = described_class.new proc { |parcel|
        expect(parcel).to be_a_kind_of(Hashie::Mash)
      }
      app.call parcel
    end

    it 'autocreate headers and message' do
      parcel = nil
      app = described_class.new proc { |parcel|
        expect(parcel.headers).to be_a_kind_of(Hashie::Mash)
        expect(parcel.message).to be_a_kind_of(Hashie::Mash)
      }
      app.call parcel
    end

  end

end
