require 'spec_helper'

require 'serf/serfer'

describe Serf::Serfer do

  describe '#call' do
    let(:request_message) {
      FactoryGirl.create :random_message
    }
    let(:response_message) {
      FactoryGirl.create :random_message
    }

    it 'calls app with message' do
      mock_app = double 'mock_app'
      mock_app.should_receive(:call).with(request_message)
      serfer = described_class.new mock_app
      serfer.call(
        headers: nil,
        message: request_message)
    end

    it 'returns a parcel' do
      mock_app = double 'mock_app'
      mock_app.
        should_receive(:call).
        with(request_message).
        and_return(response_message)
      serfer = described_class.new mock_app
      parcel = serfer.call(
        headers: nil,
        message: request_message)
      parcel.message.should == response_message
    end

    it 'sets the kind header in response' do
      mock_app = double 'mock_app'
      mock_app.
        should_receive(:call).
        with(request_message).
        and_return([response_message, 'KIND'])
      serfer = described_class.new mock_app
      parcel = serfer.call(
        headers: nil,
        message: request_message)
      parcel.headers.kind.should == 'KIND'
    end

    it 'generate uuids' do
      uuidable = double 'uuidable'
      uuidable.should_receive(:create_uuids).and_return({})
      serfer = described_class.new(
        lambda {|obj| return obj },
        uuidable: uuidable)
      serfer.call({})
    end

  end

end
