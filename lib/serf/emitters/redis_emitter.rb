require 'multi_json'
require 'redis'

module Serf

  ##
  # Emits messages/events over a redis pubsub channel.
  #
  class RedisEmitter
    DEFAULT_CHANNEL = 'serf_pubsub_channel'

    def initialize(options={})
      @redis = options.fetch(:redis) { Redis.connect }
      @channel = options.fetch(:channel) { DEFAULT_CHANNEL }
    end

    def emit(message)
      encoded_message = MultiJson.encode message
      @redis.publish @channel, encoded_message
    end

  end
end
