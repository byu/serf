require 'optser'

module Serf
module Middleware

  ##
  # Middleware to time the execution of the remaining stack, saving the
  # timing into the 'serf_elapsed_time' field in the parcel.
  class RequestTimer
    attr_reader :app
    attr_reader :timer

    def initialize(app, *args)
      opts = Optser.extract_options! args
      @app = app
      @timer = opts.get :timer, Serf::Middleware::RequestTimer::Timer
    end

    def call(parcel)
      t = timer.start
      response_parcel = app.call parcel
      response_parcel[:serf_elapsed_time] = t.mark
      return response_parcel
    end

    class Timer
      attr_reader :start_time

      class << self
        alias_method :start, :new
      end

      def initialize
        @start_time = now
      end

      def mark
        (now - @start_time).to_i
      end

      def now
        Time.now.to_f * 1_000_000
      end

    end

  end

end
end
