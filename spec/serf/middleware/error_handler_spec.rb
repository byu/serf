require 'spec_helper'

require 'factory_girl'

require 'serf/middleware/error_handler'

describe Serf::Middleware::ErrorHandler do

  describe '#call' do

    context 'has a raised error' do
      let(:request_parcel) {
        FactoryGirl.create :random_parcel
      }
      let(:response_parcel) {
        FactoryGirl.create :random_parcel
      }

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
        expect(parcel[:kind]).to eq('serf/events/caught_error')
      end

      it 'uses parcel factory w/ kind, parent, and error message' do
        mock_parcel_factory = double 'parcel_factory'
        mock_parcel_factory.
          should_receive(:create).
          with({
            parent: request_parcel,
            kind: 'serf/events/caught_error',
            message: anything()
          }).
          and_return(response_parcel)

        app = described_class.new(proc { |parcel|
            raise 'Some Runtime Error'
          },
          parcel_factory: mock_parcel_factory)
        response = app.call request_parcel
        expect(response).to eq(response_parcel)
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
        expect(parcel).to eq(response_parcel)
      end

    end

  end

end
