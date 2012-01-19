serf
====

Serf is a library that scaffolds distributed systems that are architected using
Event-Driven Service Oriented Architecture design in combinations with
the Command Query Responsibility Separation pattern.

Philosophy
==========

The underlying idea of Serf is to define a standard Ruby code interface
that standalone gems can follow to create a business verticals services.
These gems are intended to run as standalone processes in a distributed
manner.

Fundamentally, a service creates an abstraction of:
1. Messages
2. Handlers

Messages are the representation of data, documents, etc that are
marshalled from client to service, which represents the business
level interaction of the service.

Messages may be commands that a service must handle.
Messages may be events that a service emits.
Messages may be documents that represent state or business data.

Handlers are the code that is executed over Messages.
Handlers may process Command Messages.
Handlers may process observed Events that 3rd party services emit.

Services SHOULD declare a manifest to map messages to handlers, which
allows Serf to route messages and to determine blocking or non-blocking modes.

Serf App and Channels
=====================

A Serf App is a Rack-like application that accepts an ENV hash as input.
This ENV hash is simply the hash representation of a message to be processed.
The Serf App, as configured by registered manifests, will:
1. route the ENV to the proper handler
2. run the handler in blocking or non-blocking mode.
  a. The handler's serf call method will parse the ENV into a message object
    if the handler registered a Message class.
3. publish the handler's results to results or error channels.
  a. These channels are normally message queuing channels.
  b. We only require the channel instance to respond to the 'publish'
    method and accept a message (or message hash) as the argument.
4. return the handler's results to the caller if it is blocking mode.
  a. In non-blocking mode, an MessageAcceptedEvent is returned instead
    because the message will be run by the EventMachine deferred threadpool
    by default.

Not implemented as yet:
1. Create a message queue listener or web endpoint to accept messages
  and run them through the built Serf App.
2. Message Queue channels to route responses to pub/sub locations.

Service Libraries
=================

1. Service Libraries SHOULD implement message classes that include the
  ::Serf::Message helper module.
  a. Barring that, they should conform to the idea that messages may be
    hashes that define at least one attribute: 'kind'.
2. Serialization of the messages SHOULD BE Json or MessagePack (I hate XML).
  a. `to_hash` is also included.
3. Service Libraries SHOULD implement handler classes that include the
  ::Serf::Handler helper module.
4. Handler methods MUST receive a message as either as an options hash
  (with symbolized keys) or an instance of a declared Message.
5. Handler methods MUST return zero or more messages.
6. Handler methods SHOULD handle catch their business logic exceptions and
  return them as specialized messages that can be forwarded down error channels.
  Uncaught exceptions that are then caught by Serf are published as
  generic Serf::CaughtExceptionEvents, and are harder to deal with.


Serf::Message
-------------

Users of the Serf::Message module need to be aware of that:

1. Messages MUST implement the `#attributes` method to use the
  default implementations of `to_msgpack`, `to_json`, and `to_hash`.
2. Messages MAY implement validation helpers (e.g. ActiveModel or
  Virtus + Aequitas (DataMapper)). This is purely to be helpful for
  receivers (Serf::Handlers) to validate the Messages before running
  code against its data. The Serf infrastructure code does not
  validate the Messages; it is the job of the handler code.
3. Messages MAY override `Message.parse` class method if they want
  different parsing (Message object instantiation) than
  `message_class.new *args`. This parse method is called in
  Serf::Handler when the handler class has defined a Message class
  to be used to deserialize the ENV for a handler action method.
3. Messages MAY override `Message#kind` instance method or `Message.kind`
  class method to specify a message `kind` that is different than
  the tableized name of the implementing ruby class.
4. Messages MAY override `Message#to_msgpack`, `Message#to_json`, or
  `Message#to_hash` to get alternate serialization.

User that opt to roll their own Message class only need to be
aware that:

1. Message classes MUST implement `Message.parse(env={})` class method
  if said message class is to be used as the target object representation
  of a received message (from ENV hash).
    a. Serf::Handler code makes this assumption when it finds an ENV
    hash that is to be parsed into a message object.


Example
=======

    # Require our libraries
    require 'active_model'
    require 'log4r'
    require 'serf/handler'
    require 'serf/message'
    require 'serf/builder'

    # create a simple logger for this example
    logger = Log4r::Logger.new 'my_logger'
    logger.outputters = Log4r::FileOutputter.new(
      'fileOutputter',
      filename: 'log.txt')

    # my_lib/my_message.rb
    class MyMessage
      include Serf::Message
      include ActiveModel::Validations

      attr_accessor :data

      validates_presence_of :data

      def initialize(options={})
        @hi = options[:data] || 'some data here'
      end

    end

    # my_lib/my_handler.rb
    class MyHandler
      include Serf::Handler

      # Declare handlers for a 'my_message' message kind with a Message class.
      receives(
        'my_message',
        as: MyMessage,
        with: :submit_my_message)

      # This handler of 'other_message' doesn't need a Message class,
      # and will just work off the ENV hash.
      receives(
        'other_message',
        with: :submit_other_message)

      def initialize(options={})
        @logger = options[:logger]
      end

      def submit_my_message(message)
        @logger.info "In Submit My Message: #{message.inspect.to_s}"
        # Validate message because we have implement my_message with it.
        unless message.valid?
          raise ArgumentError, message.errors.full_messages.join(',')
        end
        # Do work Here...
        # And return other messages as results of work, or nil for nothing.
        return nil
      end

      def submit_other_message(message={})
        # The message here is the ENV hash because we didn't declare
        # an :as option with `receives`.
        @logger.info "In Submit Other Result: #{message.inspect.to_s}"
        return nil
      end

    end

    # my_lib/manifest.rb
    MANIFEST = {
      'my_message' => {
        # Declares which handler to use. This is the tableized
        # name of the class. It will be constantized by the serf code.
        handler: 'my_handler',
        # Default is true to process in background.
        async: true
      },
      'other_message' => {
        handler: 'my_handler',
        async: false
      }
    }

    # Helper class for this example to receive result or error messages
    # and pipe it into our logger.
    class MyChannel
      def initialize(name, logger)
        @name = name
        @logger = logger
      end
      def publish(message)
        @logger.info "#{@name} #{message}"
        #@logger.info message
      end
    end

    # Create a new builder for this serf app.
    builder = Serf::Builder.new do
      # Registers different service libary manifests.
      register MANIFEST
      # Can define arguments to pass to the 'my_handler' initialize method.
      config(
        'my_handler',
        logger: logger)
      # Create result and error channels for the handler result messages.
      error_channel MyChannel.new('errorchannel: ', logger)
      results_channel MyChannel.new('resultschannel: ', logger)
      # We pass in a logger to our Serf code: Serfer and Runners.
      logger logger
      # Optionally define a not found handler...
      # Defaults to raising an ArgumentError, 'Not Found'.
      #not_found lambda {|x| puts x}
    end
    app = builder.to_app

    # Start event machine loop.
    EM.run do
      # On the next tick
      EM.next_tick do
        logger.info "Start Tick #{Thread.current.object_id}"
        # This will submit a 'my_message' message (as a hash) to the Serf App.
        results = app.call('kind' => 'my_message')
        # Because we declared the 'my_message' kind to be handled async, we
        # should get a MessageAcceptedEvent as the results.
        logger.info "In Tick Results: #{results.inspect}"
        begin
          # Here, we're going to submit a message that we don't handle.
          # By default, an exception will be raised.
          app.call('kind' => 'unhandled_message_kind')
        rescue => e
          puts "Caught in Tick: #{e.inspect}"
        end
        logger.info "End Tick #{Thread.current.object_id}"
      end
      EM.add_timer 2 do
        EM.stop
      end
    end


Contributing to serf
====================

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.


Copyright
=========

Copyright (c) 2011-2012 Benjamin Yu. See LICENSE.txt for further details.

