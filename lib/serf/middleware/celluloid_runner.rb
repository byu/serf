require 'celluloid'

module Serf
module Middleware

  ##
  # Spins off a received message to be run async by a celluloid actor.
  #
  class CelluloidRunner

    def initialize(app, options={})
      actor_class = options.fetch(:actor_class) { CelluloidRunnerActor }
      @logger = options.fetch(:logger) { ::Serf::NullObject.new }
      @actor = actor_class.new app, logger: @logger
    end

    def call(message)
      @actor.call! message
      return [
        202,
        {
          'Content-Type' => 'text/plain'
        },
        ['Accepted']
      ]
    end
  end

  class CelluloidRunnerActor
    include Celluloid

    def initialize(app, options={})
      @app = app
      @logger = options.fetch(:logger) { ::Serf::NullObject.new }
    end

    def call(message)
      @app.call message
    rescue => e
      @logger.error e
    end
  end

end
end
