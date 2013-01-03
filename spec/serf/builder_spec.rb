require 'spec_helper'

require 'serf/builder'

describe Serf::Builder do
  let(:request_parcel) {
    FactoryGirl.create :random_parcel
  }
  let(:response_kind) {
    'MyResponseKindMessage'
  }
  let(:app) {
    lambda { |parcel|
      return response_kind, parcel
    }
  }
  subject {
    described_class.new interactor: app
  }

  describe '#to_app' do

    it 'builds a callable app' do
      expect(subject.to_app).to respond_to(:call)
    end

  end

  context 'with build app' do

    describe '#call' do

      it 'runs the app' do
        response = subject.to_app.call request_parcel
        expect(response.message).to eq(request_parcel)
        expect(response.kind).to eq(response_kind)
      end

    end

  end

end
