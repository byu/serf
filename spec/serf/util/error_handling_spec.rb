require 'spec_helper'

describe Serf::Util::ErrorHandling do
  subject { ErrorHandlingWrapper.new }

  context 'has a raised error' do

    it 'returns an error message' do
      result, error = subject.with_error_handling do
        raise 'Some Error Message'
      end
      result.should be_nil
      JsonSchemaTester.new.validate_for!(
        'serf/events/caught_error',
        error)
    end

  end

  context 'has a succeeding app' do
    let(:response_parcel) {
      FactoryGirl.create :random_parcel
    }

    it 'returns a good response parcel' do
      result, error = subject.with_error_handling do
        response_parcel
      end
      result.should == response_parcel
      error.should be_nil
    end

  end

end
