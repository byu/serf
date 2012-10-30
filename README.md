serf
====

Code your Interactors with policy protection.


Interactors
-----------

The piece of work to be done. This takes in a request, represented
by a "Message", and returns an "Event" as its result. The Interactor
is the "Domain Controller" with respect to performing
Domain Layer business logic in coordinating and interacting with
the Domain Layer's Entities (Value Objects and Entity Gateways).

1. Include the "Serf::Interactor" module in your class.
2. Implement the 'call(headers, message)' method.
3. Return the tuple: (kind, message)
  a. The kind is the string representation of the message type.
  b. Hashie::Mash is recommended for the message, nil is acceptable

Notes:

* Exceptions raised out of the interactor are then caught by Serf and
  tagged with the Serf::Error module.

Parcels
-------

A Parcel is just the package of Headers and Message. Serf's convention
represents requests and responses as (mostly) just Plain Old Hash Objects
(POHO as opposed to PORO) over the Boundaries (see Architecture Lost Years).
This simplifies marshalling over the network. It also gives us easier
semantics in defining Request and Responses without need of extra classes,
code, etc.

The Parcel in Ruby (Datastructure) is represented in three forms:

1. Serf::Parcel object, subclass of Hashie::Dash.
  a. An object that has hash-like access to headers and message,
    accessible both as 'headers' or :headers.
  b. An object w/ property accessors. `parcel.headers = {}`
  c. A splat-able object.
    Serf::Parcel.new {}, {}
    headers, message = parcel_object
2. Parcel Pair - [headers, message], a 2 element tuple (Array).
3. Parcel Hash - { headers: headers, message: message}, a 2 element Hash.

NOTE: Hashie::Mash is *Awesome*. (https://github.com/intridea/hashie)
NOTE: Serf passes headers and message as frozen Hashie::Mash instances
  to Commands' call method.
NOTE: Serf mainly deals with Serf::Parcels, returning instances as responses.

*Messages* are the representation of a Business Request or Business Event.

In the parcel, the message is the business data. It specifies what
business work needs to be done, or what business was done.

  RECOMMENDED: Use JSON Schema to validate the structure of a message.
    https://github.com/hoxworth/json-schema
    This can be implemented in the 'Policy' chain.

*Headers* are the processing meta data that is associated with a Message.

Headers provide information that would assist in processing, tracking
a Message. But does not provide business relevant information to
the Request or Event Message.

  RECOMMENDED: Recommended to be placed in headers is the 'kind' field.

The "kind" field identifies the ontological meaning of the message, which
allows Serf to properly pass the message onto the proper Command.
The convention is 'mymodule/requests/my_business_equest' for Requests,
and 'mymodule/events/my_business_event' for Events.

Examples are:
* UUIDs to track request and events, providing a sequential order of
  execution of commands. (Already Implemented by Serf).
* Current User that sent the request. For authentication and authorization.
* Host and Application Server that is processing this request.

Generally, the header information is populated only by the infrastructure
that hosts the business commands. The commands themselves do not
return any headers in the response. The commands are tasked to provide
only business relevant data in the Event messages they return.

Also note that Headers are passed to the commands. This allows commands
to possibly do extra processing based on who made the request.

Policies
--------

Serf implements Policy Chains to validate, check the incoming Parcel before
actually executing a Command.

Example Benefits:
* Authorization to execute Command.
* Validation of Message schema

Policies only need to implement a single method:

    def check!(headers, message)
      raise 'Failure' # To fail the policy, raise an error.
    end

  RECOMMENDED: Use `Serf::Errors::PolicyFailure` error type.


References
==========

Keynote: Architecture the Lost Years, by Robert Martin
  * http://confreaks.com/videos/759

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


Example
=======


    # Require our libraries
    require 'json'
    require 'yell'

    require 'serf/interactor'
    require 'serf/middleware/uuid_tagger'
    require 'serf/serfer'

    # create a simple logger for this example
    my_logger = Yell.new STDOUT

    # my_lib/my_policy.rb
    class MyPolicy

      def check!(headers, message)
        raise 'Policy Error: User is nil' unless headers.user
      end

      def self.build(*args, &block)
        new *args, &block
      end

    end

    # my_lib/my_interactor.rb
    class MyInteractor
      include Serf::Interactor

      def call(headers, message)
        raise 'Error' if message.raise_an_error

        # And return a message as result. Nil is valid response.
        return 'my_lib/events/success_event', { success: true }
      end

    end

    # Create a new builder for this serf app.
    serfer = Serf::Serfer.build(
      interactor: MyInteractor.build,
      policy_chain: [
        MyPolicy.build,
        MyPolicy.build
      ])

    # This will submit a 'my_message' message (as a hash) to Serfer.
    # Missing data field will raise an error within the interactor, which
    # will be caught by the serfer.
    begin
      results = serfer.call(nil, nil)
      my_logger.info "FAILED: Unexpected Success"
    rescue => e
      my_logger.info "Call 1: Expected Error #{e}"
    end

    # Here is good result
    results = serfer.call({
        user: 'user_info_1'
      }, {
      })
    my_logger.info "Call 2: #{results.size} #{results.to_json}"

    # Here is an error in interactor
    begin
      results = serfer.call({
          user: 'user_info_1'
        }, {
          raise_an_error: true
        })
      my_logger.info "FAILED: Unexpected Success"
    rescue => e
      my_logger.info "Call 3: Expected Error #{e}"
    end

    # Here is success with a request with UUID tagged.
    app = Serf::Middleware::UuidTagger.new serfer
    results = app.call({
        user: 'user_info_1'
      }, {
      })
    my_logger.info "Call 4: #{results.size} #{results.to_json}"


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

