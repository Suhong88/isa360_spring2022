# import necessary package.
# start Anaconda Prompt
# before running this script, install tweepy and pymongo on your computer.
# pip install tweepy
# pip install pymongo


from __future__ import print_function
import tweepy
import json
from pymongo import MongoClient
 
MONGO_HOST= 'mongodb://localhost:27017/tweetsDB'  # assuming you have mongoDB installed locally
                                             # and you want to install tweets on a databse called tweetsDB
 
WORDS = ["#climatechange", "#climatechangeisreal", "#globalwarming", "climate change"]   # choose a keyword or a list of keyword you want to investigage
 
CONSUMER_KEY= '**'
CONSUMER_SECRET= '**'
ACCESS_TOKEN= '**'
ACCESS_TOKEN_SECRET= '**'
 
class StreamListener(tweepy.StreamListener):    
    #This is a class provided by tweepy to access the Twitter Streaming API. 
 
    def on_connect(self):
        # Called initially to connect to the Streaming API
        print("You are now connected to the streaming API.")
 
    def on_error(self, status_code):
        # On error - if an error occurs, display the error / status code
        print('An Error has occured: ' + repr(status_code))
        return False
 
    def on_data(self, data):
        #This is the meat of the script...it connects to your mongoDB and stores the tweet
        try:
            client = MongoClient(MONGO_HOST)
            
            # Use twitterdb database. If it doesn't exist, it will be created.
            db = client.tweetsDB
    
            # Decode the JSON from Twitter
            datajson = json.loads(data)
            
            #grab the 'created_at' data from the Tweet to use for display
            created_at = datajson['created_at']
 
            #print out a message to the screen that we have collected a tweet
            print("Tweet collected at " + str(created_at))
            
            #insert the data into a collection called climate_change
            #if climate_change doesn't exist, it will be created.
            db.climate_change.insert(datajson)
        except Exception as e:
           print(e)
 
auth = tweepy.OAuthHandler(CONSUMER_KEY, CONSUMER_SECRET)
auth.set_access_token(ACCESS_TOKEN, ACCESS_TOKEN_SECRET)

while True:
    try:
        #Set up the listener. The 'wait_on_rate_limit=True' is needed to help with Twitter API rate limiting.
        listener = StreamListener(api=tweepy.API(wait_on_rate_limit=True)) 
        streamer = tweepy.Stream(auth=auth, listener=listener)
        print("Tracking: " + str(WORDS))
        streamer.filter(track=WORDS)
    except:
        # try after one minute if fails
        time.sleep(60)