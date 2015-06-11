require 'bundler'
Bundler.require

require 'json'
require './schoology-strategy.rb'

use Rack::Session::Cookie, :key => 'rack.session',
    :expire_after => 2592000,
    :secret => SecureRandom.hex(64)

use OmniAuth::Strategies::Schoology, ENV['SCHOOLOGY_KEY'], ENV['SCHOOLOGY_SECRET']

get '/' do
  session[:uid].inspect

end

%w(get post).each do |method|
  send(method, '/auth/:provider/callback') do
    # info
    provider = request.env['omniauth.auth'].provider
    uid = request.env['omniauth.auth'].uid
    info = request.env['omniauth.auth'].info.to_hash
    credentials = request.env['omniauth.auth'].credentials.to_hash

    # sample api call
    consumer = OAuth::Consumer.new(ENV['SCHOOLOGY_KEY'], ENV['SCHOOLOGY_SECRET'], {:site => 'https://api.schoology.com/v1'})
    access = OAuth::AccessToken.new(consumer, credentials['token'], credentials['secret'])
    data = JSON.parse(access.get("/users/#{uid}/sections").body)
    data2 = JSON.parse(access.get("/sections/134636787/assignments").body)
    classes_period = {}
    classes_ids = {}
    data['section'].each do |datum|
      title = datum["course_title"]
      period_num = datum["section_title"].split('-')[1]
      period_id = datum['id']
      if title != "Staples Library Learning Commons"
      classes_period[period_num] = title
      classes_ids[period_id] = title
        end
    end
    i = 1
    while i <= 8
      if !classes_period.has_key?(i.to_s)
        classes_period[i.to_s] = "Free"
      end
      i += 1
    end
    data2 = JSON.parse(access.get("https://api.schoology.com/v1/sections/134636787/assignments?start=0&limit=#{data2['total']}").body)

    assignments = []
    puts data2.inspect
    data2['assignment'].each do |assignment|
      puts (assignment).inspect
      date = Date.parse(assignment['due'])
      if date.ld <= Date.today.ld
        assignments.push({assignment["title"] => date})
      end
    end
    puts assignments.inspect

    session[:uid] = uid

    redirect '/'
  end
end

get '/auth/logout' do
  session.clear

  redirect '/'
end