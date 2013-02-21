require 'pg'
require 'benchmark'

USER = 100
TWEET = 100

conn = PGconn.open :dbname =>'twitter',
                   :user => 'postgres',
                   :host => 'localhost',
                   :password => ''

conn.exec 'delete from tweets'
conn.exec 'delete from users'

Benchmark.bm do |x|
  x.report('add user:') do
    USER.times do |i|
      conn.exec "insert into users (id, name) values(#{i}, \'name_#{i}\')"
    end
  end

  x.report('tweet:') do
    USER.times do |i|
      TWEET.times do |j|
        tweet_id = i * TWEET + j
        reply_id_diff = USER * TWEET / 10
        if j == 0 && tweet_id >= reply_id_diff
          conn.exec "insert into tweets (id, content, in_reply) values(#{tweet_id}, \'user_#{i}_number_#{j}\', #{tweet_id - reply_id_diff})"
        else
          conn.exec "insert into tweets (id, content) values(#{tweet_id}, \'user_#{i}_number_#{j}\')"
        end
      end
    end
  end

  x.report('get_tweet_simple:') do
    USER.times do |i|
      TWEET.times do |j|
        conn.exec "select * from tweets where id = #{i * TWEET + j}"
      end
    end
  end

  x.report('get_tweet_complex:') do
    USER.times do |i|
      TWEET.times do |j|
        conn.exec "select * from tweets as a inner join tweets as b on a.in_reply = b.id where a.id = #{i * TWEET + j}"
      end
    end
  end

  x.report('get_tweet_super_complex:') do
    USER.times do |i|
      TWEET.times do |j|
        conn.exec "with recursive r as (select * from tweets where id = #{i * TWEET + j} union all select tweets.* from tweets, r where tweets.id = r.in_reply) select * from r order by id"
      end
    end
  end
end
