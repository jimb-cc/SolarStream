require 'twitter'
require 'mongo'
require 'awesome_print'
require 'json'

include Mongoc

# monitor ratelimit
# query database to find a record
# fix time
# fix geo
# fix Fav and retweet count

# 899401972825997312
# 899401972825997312
# 899404305865854976

# set up connection to the database
puts "#{ARGV[2]} - #{ARGV[0]} - #{ARGV[0]}"

SSDB = Mongo::Client.new(["#{ARGV[2]}:27017"], :database => "solarstream", :user => ARGV[0], :password => ARGV[1])
# set the logger level for the mongo driver
Mongo::Logger.logger.level = ::Logger::WARN

# Pull the API keys in from the DB
keys  = SSDB[:api_keys].find.limit(1).first


client = Twitter::REST::Client.new do |config|
  config.consumer_key        = keys['consumer_key']
  config.consumer_secret     = keys['consumer_secret']
  config.access_token        = keys['oauth_token']
  config.access_token_secret = keys['oauth_token_secret']
end

puts "\n\nTweetFix\n--------------\n\n"


def fixTime(id,time)
	fixtime = Time.at((time.to_i)/1000)
    result = SSDB[:geosolar].update_one( { 'id' => id }, { '$set' => { 'fix.createdOn' => fixtime, 'fix.fixTS' => Time.now, 'fixed'=>true } } )
end


def updateFavAndRetweetCount(id,client)
	begin
		puts "Asking for #{id}..."
	  	tweet = client.status(id)
	    puts "The retweet count is now at #{tweet.retweet_count} and Favorites at #{tweet.favorite_count}"  
	    result = SSDB[:geosolar].update_one( { 'id' => id }, { '$set' => { 'fix.retweet_count' => tweet.retweet_count, 'fix.favorite_count'=> tweet.favorite_count, 'fix.fixTS' => Time.now, 'fixed'=>true } } )
	rescue Exception => e
		ap e
	end
end


sourceTweets = SSDB[:geosolar].find.each_with_index do |sourcetweet,i|
	start = Time.now
	puts "\n\n--Tweet fix #{i}--"

	fixTime(sourcetweet[:id],sourcetweet[:timestamp_ms])
	updateFavAndRetweetCount(sourcetweet[:id], client)

	# pad out the function to take at least 1 sec so we don't infinge the twitter rate limit
	duration = Time.now - start
	ap "--request took #{duration}"	
	if duration < 1.0
		sleep 1.0 - duration
	end
	ap "-- It's been #{Time.now - start} since we started this nonsense"
end

