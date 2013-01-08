require 'spec_helper'

require 'hashie'
require 'securerandom'

require 'serf/serfer'

describe Serf::Serfer do

  describe '#call' do
    let(:request_parcel) {
      FactoryGirl.create :random_parcel
    }
    let(:versioned_response_kind_version) {
      SecureRandom.hex
    }
    let(:versioned_response_kind) {
      "#{response_kind}\##{versioned_response_kind_version}"
    }
    let(:response_kind) {
      SecureRandom.hex
    }
    let(:response_message) {
      FactoryGirl.create :random_hash
    }
    let(:response_headers) {
      FactoryGirl.create :random_hash
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
      expect(parcel.kind).to eq(response_kind)
      expect(parcel.uuid).to_not be_nil
      expect(parcel.origin_uuid).to eq(request_parcel.origin_uuid)
      expect(parcel.parent_uuid).to eq(request_parcel.uuid)
      expect(parcel.message).to eq(response_message)
    end

    it 'uses parcel factory w/ parent (w/ nil kind+message+headers)' do
      mock_parcel_factory = double 'parcel_factory'
      mock_parcel_factory.
        should_receive(:create).
        with({
          parent: request_parcel,
          kind: nil,
          message: nil,
          headers: nil
        }).
        and_return(disconnected_response_parcel)

      serfer = described_class.new(
        lambda { |obj| },
        parcel_factory: mock_parcel_factory)
      parcel = serfer.call request_parcel

      expect(parcel).to eq(disconnected_response_parcel)
    end

    it 'uses parcel factory w/ kind, parent (w/ nil message+headers)' do
      mock_parcel_factory = double 'parcel_factory'
      mock_parcel_factory.
        should_receive(:create).
        with({
          parent: request_parcel,
          kind: response_kind,
          message: nil,
          headers: nil
        }).
        and_return(disconnected_response_parcel)

      serfer = described_class.new(
        lambda { |obj| return response_kind },
        parcel_factory: mock_parcel_factory)
      parcel = serfer.call request_parcel

      expect(parcel).to eq(disconnected_response_parcel)
    end

    it 'uses parcel factory w/ kind, parent and message (w/ nil headers)' do
      mock_parcel_factory = double 'parcel_factory'
      mock_parcel_factory.
        should_receive(:create).
        with({
          parent: request_parcel,
          kind: response_kind,
          message: response_message,
          headers: nil
        }).
        and_return(disconnected_response_parcel)

      serfer = described_class.new(
        lambda {|obj| return response_kind, response_message },
        parcel_factory: mock_parcel_factory)
      parcel = serfer.call request_parcel

      expect(parcel).to eq(disconnected_response_parcel)
    end

    it 'uses parcel factory w/ kind, parent, message and headers' do
      mock_parcel_factory = double 'parcel_factory'
      mock_parcel_factory.
        should_receive(:create).
        with({
          parent: request_parcel,
          kind: response_kind,
          message: response_message,
          headers: response_headers
        }).
        and_return(disconnected_response_parcel)

      serfer = described_class.new(
        lambda { |obj|
          return response_kind, response_message, response_headers
        },
        parcel_factory: mock_parcel_factory)
      parcel = serfer.call request_parcel

      expect(parcel).to eq(disconnected_response_parcel)
    end

    it 'moves version info from a versioned kind to the headers' do
      mock_parcel_factory = double 'parcel_factory'
      mock_parcel_factory.
        should_receive(:create).
        with({
          parent: request_parcel,
          kind: response_kind,
          message: response_message,
          headers: {
            version: versioned_response_kind_version
          }
        }).
        and_return(disconnected_response_parcel)

      serfer = described_class.new(
        lambda { |obj|
          return versioned_response_kind, response_message
        },
        parcel_factory: mock_parcel_factory)
      parcel = serfer.call request_parcel

      expect(parcel).to eq(disconnected_response_parcel)
    end

  end

end
