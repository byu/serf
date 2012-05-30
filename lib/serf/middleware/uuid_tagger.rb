require 'serf/util/uuidable'

module Serf
module Middleware

  ##
  # Middleware to add a request uuid to both the message and context
  # of the env hash. But it won't overwrite the uuid field
  # if the incoming request already has it.
  #
  class UuidTagger
    include Serf::Util::OptionsExtraction

    attr_reader :uuidable

    ##
    # @param app the app
    # @options opts [String] :field the ENV field to set with a UUID.
    #
    def initialize(app, *args)
      extract_options! args
      @app = app
      @uuidable = opts :uuidable, Serf::Util::Uuidable
    end

    def call(env)
      message = env[:message]
      message[:uuid] = uuidable.create_coded_uuid if message && !message[:uuid]

      context = env[:context]
      context[:uuid] = uuidable.create_coded_uuid if context && !context[:uuid]

      @app.call env
    end

  end

end
end
