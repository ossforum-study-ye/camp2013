require 'mongo'
require 'benchmark'

include Mongo

USER = 10000
TWEET = 100

client = MongoClient.new('10.3.6.2', 27017)
db = client['twitter']
user_col = db['users']
tweet_col = db['tweets']

user_col.remove
tweet_col.remove

Benchmark.bm do |x|
  x.report('add user') do
    USER.times do |i|
      user_col.insert({:id => i, :name => "name_#{i}"})
    end
  end

  x.report('tweet:') do
    USER.times do |i|
      user = user_col.find(:id => i).to_a[0]
      TWEET.times do |j|
        tweet_id = i * TWEET + j
        reply_id = tweet_id - USER * TWEET / 10
        if j == 0 && reply_id > -1
          reply_tweet = tweet_col.find(:id => reply_id).to_a[0]

          tweet_col.insert({:id => tweet_id, :content => "user_#{i}_#{j}", :in_reply => reply_tweet, :user => user})
        else
          tweet_col.insert({:id => tweet_id, :content => "user_#{i}_#{j}", :user => user})
        end
      end
    end
  end

  x.report('get_tweet_simple:') do
    USER.times do |i|
      TWEET.times do |j|
        tweet_col.find(:id => i * TWEET + j)
      end
    end
  end

  x.report('get_tweet_complex:') do
    USER.times do |i|
      TWEET.times do |j|
        tweet_col.find(:id => i * TWEET + j)
      end
    end
  end

  x.report('get_tweet_super_complex:') do
    USER.times do |i|
      TWEET.times do |j|
        tweet_col.find(:id => i * TWEET + j)
      end
    end
  end
end
