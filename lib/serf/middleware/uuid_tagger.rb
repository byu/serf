require 'uuidtools'

module Serf
module Middleware

  ##
  # Middleware to add a request uuid the ENV Hash to uniquely identify
  # the handling of this input. But it won't overwrite the uuid field
  # if the incoming request already has it.
  #
  class UuidTagger

    ##
    # @param app the app
    # @options opts [String] :field the ENV field to set with a UUID.
    #
    def initialize(app, options={})
      @app = app
      @field = options.fetch(:field) { 'serf.request_uuid' }
    end

    def call(env)
      env = env.dup
      env[@field] ||= UUIDTools::UUID.random_create.to_s
      @app.call env
    end

  end

end
end
