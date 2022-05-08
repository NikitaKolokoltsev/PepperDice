require 'sinatra'

get '/' do
  redirect 'http://t.me/pepper_dice_bot', 303
end
