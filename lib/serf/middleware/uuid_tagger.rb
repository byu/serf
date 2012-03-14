require 'serf/util/uuidable'

module Serf
module Middleware

  ##
  # Middleware to add a request uuid the ENV Hash to uniquely identify
  # the handling of this input. But it won't overwrite the uuid field
  # if the incoming request already has it.
  #
  class UuidTagger
    include Serf::Util::Uuidable

    ##
    # @param app the app
    # @options opts [String] :field the ENV field to set with a UUID.
    #
    def initialize(app, options={})
      @app = app
      @field = options.fetch(:field) { 'uuid' }
    end

    def call(env)
      env = env.dup
      unless env[@field.to_sym] || env[@field.to_s]
        env[@field] = create_coded_uuid
      end
      @app.call env
    end

  end

end
end
