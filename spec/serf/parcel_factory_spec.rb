require 'spec_helper'

require 'hashie'
require 'securerandom'

require 'serf/parcel_factory'

describe Serf::ParcelFactory do

  describe '#build' do
    let(:response_kind) {
      SecureRandom.hex
    }
    let(:response_headers) {
      FactoryGirl.create :random_headers
    }
    let(:response_message) {
      FactoryGirl.create :random_message
    }
    let(:parent_parcel) {
      FactoryGirl.create :random_parcel
    }

    it 'returns a Hashie Mash' do
      parcel = subject.create
      expect(parcel).to be_a_kind_of(Hashie::Mash)
    end

    it 'returns the headers as a Hashie Mash' do
      parcel = subject.create
      expect(parcel.headers).to be_a_kind_of(Hashie::Mash)
    end

    it 'sets nil kind in parcel headers' do
      parcel = subject.create
      expect(parcel.headers.kind).to be_nil
    end

    it 'sets nil kind in parcel headers to overwrite headers kind' do
      parcel = subject.create headers: response_headers
      expect(response_headers.kind).to_not be_nil
      expect(parcel.headers.kind).to be_nil
    end

    it 'sets a kind in parcel headers to overwrite headers' do
      parcel = subject.create kind: response_kind, headers: response_headers
      expect(response_headers.kind).to_not eq(response_kind)
      expect(parcel.headers.kind).to eq(response_kind)
    end

    it 'sets uuid, w/ nil origin and parent in parcel headers' do
      parcel = subject.create
      expect(parcel.headers.uuid).to_not be_nil
      expect(parcel.headers.parent_uuid).to be_nil
      expect(parcel.headers.origin_uuid).to be_nil
    end

    it 'sets uuid, origin and parent in response headers from parent' do
      parcel = subject.create parent: parent_parcel
      expect(parcel.headers.uuid).to_not be_nil
      expect(parcel.headers.parent_uuid).to eq(parent_parcel.headers.uuid)
      expect(parcel.headers.origin_uuid).
        to eq(parent_parcel.headers.origin_uuid)
    end

    it 'returns the message as a Hashie Mash' do
      parcel = subject.create
      expect(parcel.message).to be_a_kind_of(Hashie::Mash)
    end

    it 'sets empty parcel message as default' do
      parcel = subject.create
      expect(parcel[:message]).to eq({})
    end

    it 'sets the message, given a message' do
      parcel = subject.create message: response_message
      expect(parcel.message).to eq(response_message)
    end

    it 'sets meets expectations given kind, headers, message and parent' do
      parcel = subject.create(
        parent: parent_parcel,
        kind: response_kind,
        headers: response_headers,
        message: response_message)
      expect(response_headers.kind).to_not eq(response_kind)
      expect(parcel.headers.kind).to eq(response_kind)
      expect(parcel.headers.uuid).to_not be_nil
      expect(parcel.headers.parent_uuid).to eq(parent_parcel.headers.uuid)
      expect(parcel.headers.origin_uuid).
        to eq(parent_parcel.headers.origin_uuid)
      expect(parcel.headers.option_a).to eq(response_headers.option_a)
      expect(parcel.message).to eq(response_message)
    end

  end

end
