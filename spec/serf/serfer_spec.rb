require 'spec_helper'

require 'hashie'
require 'securerandom'

require 'serf/serfer'

describe Serf::Serfer do

  describe '#call' do
    let(:request_parcel) {
      Hashie::Mash.new(
        headers: request_headers,
        message: request_message)
    }
    let(:request_headers) {
      FactoryGirl.create :random_headers
    }
    let(:request_message) {
      FactoryGirl.create :random_message
    }
    let(:response_kind) {
      SecureRandom.hex
    }
    let(:response_message) {
      FactoryGirl.create :random_message
    }
    let(:disconnected_response_parcel) {
      FactoryGirl.create :random_parcel
    }

    it 'calls app with the parcel' do
      mock_app = double 'mock_app'
      mock_app.should_receive(:call).with(request_parcel)
      serfer = described_class.new mock_app
      serfer.call request_parcel
    end

    it 'returns a parcel with a kind, message and uuids' do
      mock_app = double 'mock_app'
      mock_app.
        should_receive(:call).
        with(request_parcel).
        and_return([response_kind, response_message])
      serfer = described_class.new mock_app

      parcel = serfer.call request_parcel

      # We expect the kind and message to match.
      # We also expect that the uuid is some value
      # We also expect that the response parent uuid matches request uuid
      # We also expect that the response origin uuid matches request origin's.
      expect(parcel.headers.kind).to eq(response_kind)
      expect(parcel.headers.uuid).to_not be_nil
      expect(parcel.headers.origin_uuid).
        to eq(request_parcel.headers.origin_uuid)
      expect(parcel.headers.parent_uuid).
        to eq(request_parcel.headers.uuid)
      expect(parcel.message).to eq(response_message)
    end

    it 'uses parcel factory w/ message and headers' do
      mock_parcel_factory = double 'parcel_factory'
      mock_parcel_factory.
        should_receive(:create).
        with({
          parent: request_parcel,
          kind: response_kind,
          message: response_message
        }).
        and_return(disconnected_response_parcel)

      serfer = described_class.new(
        lambda {|obj| return response_kind, response_message },
        parcel_factory: mock_parcel_factory)
      parcel = serfer.call request_parcel

      expect(parcel).to eq(disconnected_response_parcel)
    end

  end

end
