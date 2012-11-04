require 'spec_helper'

require 'serf/middleware/error_handler'

describe Serf::Middleware::ErrorHandler do

  describe '#call' do

    context 'has a raised error' do
      subject {
        described_class.new(proc { |parcel|
          raise 'Some Runtime Error'
        })
      }

      it 'returns an error parcel' do
        parcel = subject.call({})
        JsonSchemaTester.new.validate_for!(
          'serf/events/caught_error',
          parcel[:message])
      end

      it 'has an error parcel kind' do
        parcel = subject.call({})
        parcel[:headers][:kind].should == 'serf/events/caught_error'
      end
    end

    context 'has a succeeding app' do
      subject {
        described_class.new(proc { |parcel|
          response_parcel
        })
      }
      let(:response_parcel) {
        FactoryGirl.create :random_parcel
      }

      it 'returns a good response parcel' do
        parcel = subject.call({})
        parcel.should == response_parcel
      end

    end

  end

end
