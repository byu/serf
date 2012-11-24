require 'spec_helper'

require 'serf/middleware/request_timer'

describe Serf::Middleware::RequestTimer do

  describe '#call' do
    let(:empty_parcel) {
      FactoryGirl.create :empty_parcel
    }
    let(:elapsed_time) {
      rand(1000000)
    }

    it 'annotates the response parcel with the elapsed call time' do
      # Mock Timer Ojbect
      mock_timer_obj = double 'TimerObj'
      mock_timer_obj.
        should_receive(:mark).
        and_return(elapsed_time)

      # Mock Timer Class
      mock_timer_class = double 'TimerClass'
      mock_timer_class.
        should_receive(:start).
        and_return(mock_timer_obj)

      # Mock App
      mock_app = double 'MyApp'
      mock_app.
        should_receive(:call).
        with({}).
        and_return(empty_parcel)

      # Execute the Test
      request_timer = described_class.new mock_app, :timer => mock_timer_class
      response_parcel = request_timer.call({})
      response_parcel.headers.elapsed_time.should == elapsed_time
    end

  end

end
