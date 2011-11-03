require 'active_support/core_ext/hash'
require 'msgpack/rpc'

module Serf

  ##
  # A MsgpackRpc handler that is just here to act as a protective
  # facade to only expose the 'call' rpc method to MsgpackRpc clients.
  #
  class MsgpackHandler
    def initialize(app, options={})
      @app = app
    end

    def call(env)
      @app.call env.stringify_keys
    end
  end

  ##
  # Defines a Msgpack RPC Server to run to receive messages.
  #
  class MsgpackReceiver
    DEFAULT_SERVER_TRANSPORT_CLASS = MessagePack::RPC::TCPServerTransport
    DEFAULT_ADDRESS_CLASS = MessagePack::RPC::Address

    def initialize(app, options={})
      @handler = options.fetch(:handler) { MsgpackHandler.new(app) }

      @listener = options.fetch(:listener) {
        host = options.fetch(:host) { '0.0.0.0' }
        port = options.fetch(:port) { 18800 }
        address = DEFAULT_ADDRESS_CLASS.new host, port
        DEFAULT_SERVER_TRANSPORT_CLASS.new address
      }

      @rpc_class = options.fetch(:rpc_class) { MessagePack::RPC::Server }
    end

    ##
    # Runs, doesn't return.
    def run
      svr = @rpc_class.new
      svr.listen @listener, @handler
      svr.run
    end

  end

end
