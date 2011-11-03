module Serf

  autoload :Builder, 'serf/builder'
  autoload :NullObject, 'serf/null_object'

  # Emitters
  autoload :RedisEmitter, 'serf/emitters/redis_emitter'

  # Receivers
  autoload :MsgpackReceiver, 'serf/receivers/msgpack_receiver'
  autoload :RedisPubsubReceiver, 'serf/receivers/redis_pubsub_receiver'

  module Middleware
    autoload :CelluloidRunner, 'serf/middleware/celluloid_runner'
    autoload :EmRunner, 'serf/middleware/em_runner'
    autoload :KindMapper, 'serf/middleware/kind_mapper'
  end

end

require 'serf/version'
