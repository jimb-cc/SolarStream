#require 'twitter'
require 'tweetstream'
require 'mongo'
require 'awesome_print'
require 'json'

include Mongo

#&amp is being stripped out, fix.


# we're not interested in retweets
def isRetweet?(tweet)
	return true if tweet[0,2] == "RT"
	false
end

# set up connection to the database
puts "#{ARGV[2]} - #{ARGV[0]} - #{ARGV[0]}"

DKDB = Mongo::Client.new(["#{ARGV[2]}:27017"], :database => "solarstream", :user => ARGV[0], :password => ARGV[1])
# set the logger level for the mongo driver
Mongo::Logger.logger.level = ::Logger::WARN

# Pull the API keys in from the DB
keys  = DKDB[:api_keys].find.limit(1).first


# Access for the Twitter streaming client
TweetStream.configure do |config|
		config.consumer_key       = keys['consumer_key']
		config.consumer_secret    = keys['consumer_secret']
		config.oauth_token        = keys['oauth_token']
		config.oauth_token_secret = keys['oauth_token_secret']
		config.auth_method        = :oauth
end

puts "\n\n\n-----SolarStream Alpha-----\n\n\n"


# Create a tweet stream
TweetStream::Client.new.track('eclipse') do |tweet|

	if isRetweet?(tweet.text)
		puts "-RETWEET-"
	else 
		ap "#{tweet.id} -- #{tweet.text}"
		# insert the tweet object into the DB
		id = DKDB[:tweets].insert_one(tweet.to_h)
		begin
			#fav = client.favorite(tweet.id)
			rescue Exception => e
			ap e
		end
	end	
end

