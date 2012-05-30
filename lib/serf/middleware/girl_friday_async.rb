require 'girl_friday'

require 'serf/util/options_extraction'
require 'serf/util/uuidable'

module Serf
module Middleware

  class GirlFridayAsync
    include Serf::Util::OptionsExtraction

    attr_reader :uuidable
    attr_reader :queue

    def initialize(app, *args)
      extract_options! args

      @uuidable = opts :uuidable, Serf::Util::Uuidable

      @queue = ::GirlFriday::WorkQueue.new(
          opts(:name, :serf_runner),
          :size => opts(:workers, 1)) do |env|
        app.call env
      end
    end

    def call(env)
      queue.push env
      response = uuidable.create_uuids env.message
      response.kind = 'serf/messages/message_accepted_event'
      response.message = env.message
      response.context = env.context
      return response
    end

  end

end
end
