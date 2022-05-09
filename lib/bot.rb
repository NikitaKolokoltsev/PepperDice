require 'telegram/bot'
require 'rmagick'
require 'pry'
require 'json'
require_relative './dice'
require_relative './image'

FALLBACK_MESSAGE = <<-TXT
Available commands:
/start - Start the bot
TXT

class Bot
  def initialize
    @bot = nil
    token = ENV['PEPPER_DICE_BOT_TOKEN']

    Telegram::Bot::Client.run(token) do |bot|
      @bot = bot
      bot.listen do |message|
        case message
        when Telegram::Bot::Types::Message
          process_message(message)
        when Telegram::Bot::Types::CallbackQuery
          process_callback_query(message)
        end
      end
    end
  end

  private

  def process_message(message)
    case message.text
    when '/start'
      actions = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: ['roll'], resize_keyboard: true)

      @bot.api.send_message(
        chat_id: message.chat.id,
        text: 'Wanna roll?',
        reply_markup: actions
      )
    when 'roll'
      combination = Dice.roll
      combination_name = Dice.name(combination)

      image = Image.new(combination).build.write('out.png')

      @bot.api.send_message(
        chat_id: message.chat.id,
        text: "First roll: #{combination} - #{combination_name}"
      )
      @bot.api.send_photo(
        chat_id: message.chat.id,
        photo: Faraday::UploadIO.new('out.png', 'image/png'),
        reply_markup: reroll_keyboard(combination)
      )
    else
      @bot.api.send_message(
        chat_id: message.chat.id,
        text: FALLBACK_MESSAGE
      )
    end
  end

  def process_callback_query(query)
    data = JSON.parse(query.data, symbolize_names: true)

    case data[:type]
    when 'finish'
      combination = data[:c]
      combination_name = Dice.name(combination)

      @bot.api.send_message(
        chat_id: query.message.chat.id,
        text: "Result: #{combination} - #{combination_name}"
      )
    when 'dice_reroll'
      reroll_dice = data[:d]
      picked = data[:p].include?(reroll_dice[1]) ?
        data[:p].reject{ |index| index == reroll_dice[1] } :
        data[:p].concat([reroll_dice[1]])
      combination = data[:c]

      image = Image.new(combination, picked).build.write('out.png')

      @bot.api.edit_message_media(
        chat_id: query.message.chat.id,
        message_id: query.message.message_id,
        media: { type: 'photo', media: 'attach://image' }.to_json,
        image: Faraday::UploadIO.new('out.png', 'image/png'),
        reply_markup: reroll_keyboard(combination, picked)
      )
    when 'reroll'
      old_combination = data[:c]
      picked = data[:p]

      rerolled = Dice.roll(picked.count)

      combination = old_combination
        .each_with_index
        .reject { |_, index| picked.include?(index) }
        .map(&:first)
        .concat(rerolled)
      combination_name = Dice.name(combination)

      image = Image.new(combination).build.write('out.png')

      @bot.api.edit_message_reply_markup(
        chat_id: query.message.chat.id,
        message_id: query.message.message_id,
        reply_markup: reroll_keyboard(old_combination, picked, rerolled: true)
      )
      @bot.api.send_photo(
        chat_id: query.message.chat.id,
        photo: Faraday::UploadIO.new('out.png', 'image/png'),
      )
      @bot.api.send_message(
        chat_id: query.message.chat.id,
        text: "Result: #{combination} - #{combination_name}"
      )
    end
  end

  private

  def reroll_keyboard(combination, picked = [], rerolled: false)
    combination_with_indexes = combination.each_with_index.to_a

    reroll_buttons = combination_with_indexes.map do |dice|
      reroll_button(dice, combination, picked, rerolled: rerolled)
    end.each_slice(3).to_a

    unless rerolled
      reroll_buttons.push([
        Telegram::Bot::Types::InlineKeyboardButton.new(
          text: picked.empty? ? 'finish' : 'reroll',
          callback_data: {
            type: picked.empty? ? 'finish' : 'reroll',
            c: combination,
            p: picked
          }.to_json
        )
      ])
    end
    Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: reroll_buttons)
  end

  def reroll_button(dice, combination, picked = [], rerolled: false)
    callback_data = {
      type: 'dice_reroll',
      d: dice,
      c: combination,
      p: picked
    }.to_json

    Telegram::Bot::Types::InlineKeyboardButton.new(
      text: "#{picked.include?(dice[1]) ? '✓ ' : ''}#{dice[0]} | #{Dice.symbol(dice[0])}",
      callback_data: rerolled ? {}.to_json : callback_data
    )
  end
end


# {
#   type: 'dice_reroll' | 'reroll',
#   d: dice, # [number, index]
#   c: combination, # [1, 3, 3, 5, 6]
#   p: picked, # [0, 3, 4]
# }
