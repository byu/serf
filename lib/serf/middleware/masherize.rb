require 'hashie'

module Serf
module Middleware

  ##
  # Middleware to turn an env into a Hashie::Mash.
  #
  class Masherize

    ##
    # @param app the app
    #
    def initialize(app)
      @app = app
    end

    def call(env)
      @app.call Hashie::Mash.new(env)
    end

  end

end
end
