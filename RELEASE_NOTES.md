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
* Added epoll and kqueue EventMachine support
* Added on___interval and on_inited callbacks

Version 1.0.5
=============

* Force SSL to comply with

Version 1.0.0
=============

* Swappable JSON backend support
* Switches to use EventMachine instead of Yajl for the HTTP Stream
* Support reconnect and on_error