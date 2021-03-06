serf
====

Code your Interactors with policy protection.

Serf (a Serf App) -- an individual rack-like call chain.
* Interactors define your business logic
* Policies decide access
* Middleware augment the request processing

Serf Map -- a set of Serfs.
* A registry of Serfs, mapped by the parcel kinds.

Serf Links
----------

* Source: https://github.com/byu/serf
* Continuous Integration: https://travis-ci.org/byu/serf
  * [![Build Status](https://secure.travis-ci.org/byu/serf.png)](http://travis-ci.org/byu/serf)
* RubyGems: http://rubygems.org/gems/serf
* RubyDocs: http://rubydoc.info/gems/serf

Interactors
-----------

The piece of work to be done. This takes in a request, represented by the
"Message" within the given "Parcel", and returns an "Event" as its result.
The Interactor is the "Domain Controller" with respect to performing
Domain Layer business logic in coordinating and interacting with
the Domain Layer's Model (Entities, Value Objects and Entity Gateways).

1. Include the "Serf::Interactor" module in your class.
2. Implement the 'call(parcel)' method.
3. Return the tuple: (kind, message, headers)
  a. The kind is the string representation of the message type,
    This field is RECOMMENDED.
  b. The message field provides detailed return data about the
    interactor's processing. The main meat of the Domain Object.
    Hashie::Mash is suggested for the message, nil is acceptable.
  c. The headers are OPTIONAL. The headers are there primarily to return
    out of band data about the processing of the request. For example,
    the Interactor can return debug tags about connections to external
    databases.
    The *ONE* semantic relevant piece of information is that the
    Interactor may specify the version the domain object, as represented
    by the message of type 'kind', in the 'version' header field.
  d. By default, returning nil for both kind and message will still
    result in a response parcel signifying that some Interactor received
    the inbound parcel. But that is just a almost worthless piece of
    information for the observer.

The reason that the interactor SHOULD return a kind is to properly
identify the semantic meaning of the returned message, even if
said returned message is empty. This also assists the handling
of response parcels in other pipelines without the need to
introspect the parcel's message.

Example:

    require 'hashie'
    require 'optser'

    class MyInteractor
      attr_reader :model

      def initialize(*args, &block)
        # Do some validation here, or extra parameter setting with the args
        opts = Optser.extract_options! args
        @model = opts :model, MyModel
      end

      def call(parcel)
        # Do something w/ the message and opts.
        # Simple data structures for the Interactor's "Request".

        item = model.find parcel.message.model_id

        # Make a simple data structure as the Interactor "Response".
        response = Hashie::Mash.new
        response.item = item
        # Return the response 'kind' and the response data.
        return 'my_app/events/did_something', response
      end
    end


Parcels
-------

A Parcel is just the package of Headers and Message. Serf's convention
represents requests and responses as (mostly) just Plain Old Hash Objects
(POHO as opposed to PORO) over the Boundaries (see Architecture Lost Years).
This simplifies marshalling over the network. It also gives us easier
semantics in defining Request and Responses without need of extra classes,
code, etc.

The Parcel in Ruby (Datastructure) is represented simply as a hash.

* The *message* is stored in the "message" property of the parcel.
* And  *header* fields exist in the top level namespace of the parcel.

For example,

    {
      kind: 'serf/messages/my_kind',
      uuid: 'gvGshlXTEeKj-AQMzuOZ7g',
      another_header_field: '123456',
      message: {
        # Some message object
      }
    }

Serf *RESERVES* the following set of header names:

* kind
* version
* message
* uuid
* parent_uuid
* origin_uuid
* serf_*

*Messages* are the representation of a Business Request or Business Event.

In the parcel, the message is the business data. It specifies what
business work needs to be done, or what business was done.
Everything that an Interactor needs to execute its Use Case SHOULD
be in the message.

  RECOMMENDED: Use JSON Schema to validate the structure of a message.
    https://github.com/hoxworth/json-schema
    This can be implemented in the 'Policy' chain.

*Headers* are the processing meta data that is associated with a Message.

Headers provide information that would assist in processing, tracking
a Message. But SHOULD NOT provide business relevant information to
the Interactor for it to process a Request or Event Message.

*kind* field identifies the ontological meaning of the message, which
may be used to route messages over messaging channels to Interactors.
The convention is 'mymodule/requests/my_business_request' for Requests,
and 'mymodule/events/my_business_event' for Events.

*version* field MAY be used to identify the semantic version of the
  message of the given 'kind'. The triplet of (kind, version, message)
  constitutes the prime parts of domain object as represented by the
  parcel. All other header fields are incidental data that pertain to
  the processing. This field is optional, and is returned in the
  headers portion of the interactor's return results.

*UUIDs* are used to track request and events, providing a sequential
order of execution of commands. Already Implemented by Serf middleware.

* uuid - The identification of the specific parcel.
* parent_uuid - The identification of the parcel that caused the current
  parcel to be generated.
* origin_uuid - The original parcel (request or event) that started
  the chain of requests and event parcels to be generated from Interactors
  processing.

The format of the UUIDs is Serf's `coded_uuid`. It is a URI safe base64
string encoded from a UTC timestamped Type 1 UUID. This allows for both
good uniqueness and timestamp auditing (if servers are network time synced).

*serf headers* are prefixed with the "serf_" string. Example:

    {
      kind: 'my_lib/messages/my_kind',
      serf_elapsed_time: 12034,
      message: {
      }
    }

Applications can add their own headers to parcels for application
specific tracking. Namespacing SHOULD be used.

For example,

    {
      kind: 'my_lib/messages/my_kind',
      my_middleware: {
        data_point_a: 1234
      },
      my_middleware_data_poing_b: 5678,
      message: {
      }
    }

Examples of other header uses:

* Current User that sent the request. For authentication and authorization.
* Host and Application Server that is processing this request.

Generally, the header information is populated only by the infrastructure
that hosts the Interactors. The Interactors themselves do not
return any headers in the response. The Interactors are tasked to provide
only business relevant data in the Event messages they return.

However, the full request parcel is given to the Interactors so the
request's header information can be used to annotate subsequent
chained requests to other Interactors. For example, the UUIDs in headers in
"Request A" given to "Interactor A" can be used to generate new tracking
UUID headers for "Request B" that is sent to "Interactor B". This allows
us to track the origin point of any piece of processing request and event..

NOTE: Hashie::Mash is *Awesome*. (https://github.com/intridea/hashie)
NOTE: Serf passes the parcel as frozen Hashie::Mash instances
  to Interactor' call method by default.

Policies
--------

Serf implements Policy Chains to validate, check the incoming Parcels before
actually executing Interactors.

Example Benefits:
* Authorization to execute Command.
* Validation of Message schema

Policies only need to implement a single method:

    def check!(parcel)
      raise 'Failure' # To fail the policy, raise an error.
    end

  RECOMMENDED: Use `Serf::Errors::PolicyFailure` error type.


Thread Safety
-------------

Yes and No, it depends:
* Serf Middleware and Serf Utils are all *Thread Safe* by default.
  It may not be the case if thread unsafe options are passed in the
  instantiation of these objects.
* Built Serfs are *Thread Safe* **if** the developer took care
  in the creation of the Interactors and in the dependency injection
  wiring of the Serfs by the builder and loader.
* The Builder and Loader are *Thread UNSAFE* because it just doesn't make
  sense that multiple threads should compete/coordinate in the creation
  and wiring of the created Serfs (Serf Apps) and Serf Maps.
  This is usually done at start up by the main thread.
  This includes the utility classes that the loader uses.


References
==========

Keynote: Architecture the Lost Years, by Robert Martin
  * http://confreaks.com/videos/759
  * http://vimeo.com/43612849

Domain Driven Design by Eric Evans:
  * http://books.google.com/books?id=7dlaMs0SECsC&dq=domain+driven+design

Patterns of Enterprise Application Architecture by Martin Fowler
  * http://martinfowler.com/books/eip.html
  * Command (Unit of Work) Pattern
  * Event Sourcing

Enterprise Integration Patterns by Hohpe and Woolf
  * http://www.eaipatterns.com/

DDD for Rails Developers Series:
  * http://rubysource.com/ddd-for-rails-developers-part-1-layered-architecture/
  * http://rubysource.com/ddd-for-rails-developers-part-2-entities-and-values/ 
  * http://rubysource.com/ddd-for-rails-developers-part-3-aggregates/

DCI in Ruby
  * Maybe use DCI to better manage business logic in Entities.
  * http://mikepackdev.com/blog_posts/24-the-right-way-to-code-dci-in-ruby
  * http://mikepackdev.com/blog_posts/35-dci-with-ruby-refinements
  * http://nicksda.apotomo.de/2011/12/ruby-on-rest-2-representers-and-the-dci-pattern/

CQRS
  * http://www.udidahan.com/2009/12/09/clarified-cqrs/
  * http://elegantcode.com/2009/11/11/cqrs-la-greg-young/
  * http://elegantcode.com/2009/11/20/cqrs-the-domain-events/

Life beyond Distributed Transactions: an Apostate’s Opinion by Pat Helland
  * http://www.ics.uci.edu/~cs223/papers/cidr07p15.pdf

Building on Quicksand by Pat Helland
  * http://arxiv.org/ftp/arxiv/papers/0909/0909.1788.pdf

The Domain Layer (from DDD):

1. Entities (Model Entities)- What your application is.
  * Also remember Value Objects.
  * How your Domain Model is structured, but NOT necessarily tied to the
    underlying storage infrastructure.
  * http://rubysource.com/ddd-for-rails-developers-part-2-entities-and-values/
2. Domain Controllers (Interactors) - What your application does.
  * The business logic of coordinating different entities.
    Different than a Rails controller.
  * Keynote: Architecture The Lost Years
    Robert Martin
    Ruby Midwest 2011
    http://confreaks.com/videos/759
  * Your Rails Application is Missing a Domain Controller
    Nicholas Henry
    http://blog.firsthand.ca/2011/12/your-rails-application-is-missing.html
3. There is a balancing game of what business logic code lives in an
    Entity vs a Domain Controller... Do what works for you.
    But mostly follow "Use Cases" in Domain Controllers,
    and "Application Agnostic Logic" in Entities.


Serf Builder Example
====================

    # Require our libraries
    require 'json'
    require 'yell'

    require 'serf/builder'

    # create a simple logger for this example
    my_logger = Yell.new STDOUT

    # my_lib/my_policy.rb
    class MyPolicy

      def check!(parcel)
        raise 'Policy Error: User is nil' unless parcel.current_user
      end

    end

    # my_lib/my_interactor.rb
    class MyInteractor

      def call(parcel)
        raise 'Error' if parcel.message.raise_an_error

        # And return a message as result. Nil is valid response.
        return 'my_lib/events/success_event',
          { success: true },
          { version: "1.2.3" }

        # Optionally just return the kind
        # return 'my_lib/events/success_event'
      end

    end

    # Create a new builder for this Serf (aka Serf App).
    serf = Serf::Builder.new(
      interactor: MyInteractor.new,
      policy_chain: [
        MyPolicy.new
      ]).to_app

    # This will submit a 'my_message' message (as a hash) to Serfer.
    # Missing data field will raise an error within the interactor, which
    # will be caught by the serfer.
    results = serf.call nil
    my_logger.info "Call 1: #{results.to_json}"

    # Here is good result
    results = serf.call(
      current_user: 'user_info_1',
      message: {
      })
    my_logger.info "Call 2: #{results.to_json}"

    # Here get an error that was raised from the interactor
    results = serf.call(
      current_user: 'user_info_1',
      message: {
        raise_an_error: true
      })
    my_logger.info "Call 3: #{results.to_json}"


Serf Loader Example
===================

Look inside the example subdirectory for the serf files in this example.


    ####
    ## File: example/serfs/create_widget.serf
    ####

    require 'json'
    # require 'subsystem/commands/my_create_widget'
    # Throwing in this class definition to make example work
    class MyCreateWidget

      def initialize(logger, success_message)
        @logger = logger
        @success_message = success_message
      end

      def call(parcel)
        @logger.info "In My Create Widget, creating a widget: #{parcel.to_json}"
        return 'subsystem/events/mywidget_created',
          { success_message: @success_message }
      end
    end

    ##
    # Registers a serf that responds to a parcel with the given request "kind".
    # The interactor is instantiated by asking for other components in the
    # registry and for parameters set in the environment variable.
    registry.add 'subsystem/requests/create_widget' do |r, env|
      serf interactor: MyCreateWidget.new(r[:logger], env[:success_message])
    end


    ####
    ## In another ruby script, where we may load and use serfs.
    ####

    require 'hashie'
    require 'json'
    require 'yell'

    require 'serf/loader'

    # Making a logger for the top level example
    logger = Yell.new STDOUT

    # Globs to search for serf files
    globs = [
      'example/**/*.serf'
    ]
    # The serf requests that the loaded Serf Map will handle.
    serfs = [
      'subsystem/requests/create_widget'
    ]
    # A simple environment variables hash, runtime configuration
    env = Hashie::Mash.new(
      success_message: 'Some environment variable like redis URL'
    )

    # Loading the configuration, creating the serfs.
    serf_map = Serf::Loader.serfup globs: globs, serfs: serfs, env: env

    # Make an example request parcel
    request_parcel = {
      kind: 'subsystem/requests/create_widget',
      message: {
        name: 'some widget name'
      }
    }

    #
    # Look up the create widget serf by a request kind name,
    # execute the serf, and log the results
    serf = serf_map[request_parcel[:kind]]
    results = serf.call request_parcel
    logger.info results.to_json


Contributing
============

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

Copyright
=========

Copyright (c) 2011-2012 Benjamin Yu. See LICENSE.txt for further details.

