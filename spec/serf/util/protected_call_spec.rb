require 'spec_helper'

describe Serf::Util::ProtectedCall do
  subject { ProtectedCallWrapper.new }

  context 'has a raised error' do

    it 'returns an error message' do
      result, error = subject.pcall do
        raise 'Some Error Message'
      end
      result.should be_nil
      error.should be_a_kind_of(RuntimeError)
    end

  end

  context 'has a succeeding app' do
    let(:response_parcel) {
      FactoryGirl.create :random_parcel
    }

    it 'returns a good response parcel' do
      result, error = subject.pcall do
        response_parcel
      end
      result.should == response_parcel
      error.should be_nil
    end

  end

end
