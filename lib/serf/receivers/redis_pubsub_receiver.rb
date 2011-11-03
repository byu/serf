require 'active_support/core_ext/hash'
require 'multi_json'
require "redis"

module Serf

  ##
  # Defines a receiver that listens for messages from a subscribed
  # Redis pubsub channel.
  #
  class RedisPubsubReceiver

    def initialize(app, options={})
      @app = app

      @redis = options.fetch(:redis) { Redis.connect }
      @channel = options.fetch(:channel) { 'serf_pubsub_channel' }
      @logger = options.fetch(:logger) { ::Serf::NullObject.new }
    end

    ##
    # Runs, doesn't return.
    def run
      @redis.subscribe(@channel) do |on|
        on.message do |channel, message|
          begin
            decoded_message = MultiJson.decode message
            raise 'Received non-hash JSON' unless decoded_message.kind_of? Hash
            @app.call decoded_message.stringify_keys
          rescue => e
            @logger.error e
          end
        end
      end
    end

  end
end
