require 'eventmachine'

require 'serf/util/null_object'

module Serf
module Middleware

  class EmRunner
    def initialize(app, options={})
      @em = options.fetch(:event_machine) { EM }
      @app = app
      @logger = options.fetch(:logger) { ::Serf::Util::NullObject.new }
    end

    def call(env)
      @em.defer(proc do
        begin
          @app.call env
        rescue => e
          @logger.error e
        end
      end)
      return [
        202,
        {
          'Content-Type' => 'text/plain'
        },
        ['Accepted']
      ]
    end
  end

end
end
