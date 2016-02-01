+1
+require "rubygems"
+2
+require "tweetstream"
+3
+require "em-http-request"
+4
+require "simple_oauth"
+5
+require "json"
+6
+require "uri"
+7
+ 
+8
+# config oauth
+9
+OAUTH = {
+10
+ :consumer_key => "jh6436X2uErz6N6XMbVzcjNw4",
+11
+ :consumer_secret => "iFRY44VvLdSU2EiUwJQ18GDOuJY5FyS3KH2ofkq3Ugrqnhs6Mh",
+12
+ :token => "4823445898-CrbD1hv1fYmw8JQytYyiWf5S3HkYyEjA4Yl3lhn",
+13
+ :token_secret => "an0IMmW5NBzXRtpgCS2jcWnQy3CRFEXTSbWENf9cDCdjM"
+14
+}
+15
+ACCOUNT_ID = OAUTH[:token].split("4823445898").first.to_i
+16
+ 
+17
+TweetStream.configure do |config|
+18
+ config.consumer_key       = OAUTH[:jh6436X2uErz6N6XMbVzcjNw4]
+19
+ config.consumer_secret    = OAUTH[:iFRY44VvLdSU2EiUwJQ18GDOuJY5FyS3KH2ofkq3Ugrqnhs6Mh]
+20
+ config.oauth_token        = OAUTH[:4823445898-CrbD1hv1fYmw8JQytYyiWf5S3HkYyEjA4Yl3lhn]
+21
+ config.oauth_token_secret = OAUTH[:an0IMmW5NBzXRtpgCS2jcWnQy3CRFEXTSbWENf9cDCdjM]
+22
+ config.auth_method = :oauth
+23
+end

1
@loucodett  = TweetStream::Client.new
2
 
3
puts "[STARTING] bot..."
4
@loucodett.userstream() do |status| 
5
  sdv?
6
  puts status.text  # sdv?
7
6
if !status.retweet? && 
7
   status.in_reply_to_user_id? && status.in_reply_to_user_id == ACCOUNT_ID &&
8
   status.text[-1] == "?"
9
 
10
     tweet = {
11
       "status" => "@#{status.user.screen_name} " + %w(Sim Não Talvez).sample,
12
       "in_reply_to_status_id" => status.id.to_s
13
     }
14
 
15
     bot.rb
16
 end
17
end

twurl = URI.parse("https://api.twitter.com/1.1/statuses/update.json")
16
     authorization = SimpleOAuth::Header.new(:post, twurl.to_s, tweet, OAUTH)
17
 
18
     http = EventMachine::HttpRequest.new(twurl.to_s).post({
19
       :head => {"Authorization" => authorization},
20
       :body => tweet
21
     })
22
     http.errback {
23
       puts "[CONN_ERROR] errback"
24
     }
25
     http.callback {
26
       if http.response_header.status.to_i == 200
27
         puts "[HTTP_OK] #{http.response_header.status}"
28
       else
29
         puts "[HTTP_ERROR] #{http.response_header.status}"
30
       end
31
     }
32
 
33
 end
34
end
