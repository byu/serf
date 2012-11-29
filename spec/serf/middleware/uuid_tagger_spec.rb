require 'spec_helper'

require 'serf/middleware/uuid_tagger'

describe Serf::Middleware::UuidTagger do

  describe '#call' do

    it 'adds uuid the parcel header' do
      parcel = {}
      app = described_class.new proc { |parcel|
        expect(parcel[:headers][:uuid]).to_not be_nil
      }
      app.call parcel
    end

    it 'does not change the existing uuid' do
      uuid = '0d3eccaabcc46c3bcbe2a53c4505e352'
      parcel = {
        headers: {
          uuid: uuid
        }
      }
      app = described_class.new proc { |parcel|
        expect(parcel[:headers][:uuid]).to eq(uuid)
      }
      app.call parcel
    end

  end

end
