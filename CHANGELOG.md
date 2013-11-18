Version 2.6.0
=============
* Re-implemented multi_json for response parsing
* added on_control callback method for Site Streams
* fixed issue with Site Stream add/remove when passed a single user id (philgyford)
* raised em-twitter dependency to 0.3.0 to resolve issues with ruby 2.0.0

Version 2.5.0
=============
* added proxy support

Version 2.4.0
=============
* Revert "use extract_options! from the Twitter gem"
* Reorganize development and test dependencies

Version 2.3.0
=============
* Added support for Site Stream friends list
* Update paths for API 1.1
* Added stall warning handling

Version 2.2.0
=============
* Change method to request_method

Version 2.1.0
=============
* Disable identity map to reduce memory usage
* Added options support to UserStreams

Version 2.0.1
=============
* Fixed Twitter gem objects
* Added on_unauthorized callback method (koenpunt)

Version 2.0.0
=============
* Added Site Stream support
* Switched to [em-twitter](https://github.com/spagalloco/em-twitter) for underlying streaming lib
* Switched to Twitter gem objects instead of custom hashes, see [47e5cd3d21a9562b3d959bc231009af460b37567](https://github.com/intridea/tweetstream/commit/47e5cd3d21a9562b3d959bc231009af460b37567) for details (sferik)
* Made OAuth the default authentication method
* Removed on_interval callback method
* Removed parser configuration option

Version 1.1.5
=============
* Added support for the scrub_geo response (augustj)
* Update multi_json and twitter-stream version dependencies

Version 1.1.4
=============
* Added Client#connect to start streaming inside an EM reactor (pelle)
* Added shutdown_stream to cleanly stop the stream (lud)
* Loosened multi_json dependency for Rails 3.2 compatibiltiy

Version 1.1.3
=============
* Added on_reconnect callback method

Version 1.1.2
=============
* Added support for statuses/links
* Client now checks that specified json_parser can be loaded during initialization

Version 1.1.1
=============
* Fix for 1.8.6 compatibility

Version 1.1.0
=============
* OAuth authentication
* User Stream support
* Removed swappable JSON backend support for MultiJson
* Added EventMachine epoll and kqueue support
* Added on_interval callback
* Added on_inited callback

Version 1.0.5
=============
* Force SSL to comply with

Version 1.0.0
=============
* Swappable JSON backend support
* Switches to use EventMachine instead of Yajl for the HTTP Stream
* Support reconnect and on_error
