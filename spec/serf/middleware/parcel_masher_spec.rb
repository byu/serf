require 'spec_helper'

require 'hashie'

require 'serf/middleware/parcel_masher'

describe Serf::Middleware::ParcelMasher do

  describe '#call' do

    it 'should Hashie::Mash the parcel' do
      parcel = nil
      app = described_class.new proc { |parcel|
        parcel.is_a?(Hashie::Mash).should be_true
      }
      app.call parcel
    end

    it 'should autocreate headers and message' do
      parcel = nil
      app = described_class.new proc { |parcel|
        parcel.headers.is_a?(Hashie::Mash).should be_true
        parcel.message.is_a?(Hashie::Mash).should be_true
      }
      app.call parcel
    end

  end

end
