require 'spec_helper'

require 'hashie'

require 'serf/parcel_builder'

describe Serf::ParcelBuilder do

  describe '#build' do
    let(:random_headers) {
      FactoryGirl.create :random_headers
    }
    let(:random_message) {
      FactoryGirl.create :random_message
    }

    it 'returns a Hashie' do
      parcel = subject.build
      parcel.should be_a_kind_of(Hashie::Mash)
    end

    it 'sets default parcel headers' do
      parcel = subject.build
      parcel[:headers].should == {}
    end

    it 'sets default parcel message' do
      parcel = subject.build
      parcel[:headers].should == {}
    end

    it 'sets given headers and message' do
      parcel = subject.build random_headers, random_message
      parcel[:headers].should == random_headers
      parcel[:message].should == random_message
    end

    it 'will coerce headers and message into Hashie::Mash' do
      parcel = subject.build nil, nil
      parcel[:headers].should be_a_kind_of(Hashie::Mash)
      parcel[:message].should be_a_kind_of(Hashie::Mash)
    end

  end

end
