require 'telegram/bot'
require 'net/http'
require 'json'

class PassengersBot
  TOKEN    = ENV['PASSENGERS_BOT_TOKEN']
  API_HOST = 'http://localhost:4567/api'

  def run
    Telegram::Bot::Client.run(TOKEN) do |bot|
      @markup ||= message_markup
      @bot      = bot

      @bot.listen do |message|
        case message
        when Telegram::Bot::Types::CallbackQuery
          process_callback(message)
        when Telegram::Bot::Types::Message
          process_input(message)
        end
      end
    end
  end

  private

  def process_input(message)
    case message.text
    when /start/i
      @bot.api.send_message(
        chat_id: message.chat.id,
        text: "Hi, #{message.from.first_name}! Here you can buy a train ticket and see all your tickets you have bought before.",
        reply_markup: @markup
      )
    when /,\s*/
      user_info = message.text.split(',').map(&:strip)
      user_data = {
        first_name: user_info[0],
        last_name:  user_info[1],
        birth_date: user_info[2]
      }

      res = post_request("#{API_HOST}/create_user", user_data)
      @bot.api.send_message(chat_id: message.chat.id,text: "Your data saved!", reply_markup: @markup)
    else
      @bot.api.send_message(chat_id: message.chat.id,text: "Sorry, I don't understand that", reply_markup: @markup)
    end
  end

  def process_callback(message)
    case message.data
    when 'save'
      @bot.api.send_message(
        chat_id: message.from.id,
        text: "Write down your data in following format:\n
        First name, Last name, Date of Birth (dd.mm.yyyy)"
      )
    when 'list'
      users_data = get_request("#{API_HOST}/list_users")
      @bot.api.send_message(chat_id: message.from.id, text: users_data.join(','), reply_markup: @markup)
    else
      @bot.api.send_message(chat_id: message.from.id, text: "Bye!")
    end
  end

  def message_markup
    buttons_data = { 'save': 'Save user data', 'list': 'List users data', 'stop': 'Stop'}
    buttons = buttons_data.map {
      |data, text| Telegram::Bot::Types::InlineKeyboardButton.new(text: text, callback_data: data)
    }
    Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: buttons)
  end

  def get_request(url)
    uri = URI(url)
    set_connection(uri)

    req = Net::HTTP::Get.new(uri)
    parse_response(req)
  end

  def post_request(url, body = '')
    uri = URI(url)
    set_connection(uri)

    req = Net::HTTP::Post.new(uri)
    req['Content-Type']  = "application/json"
    req.body             = body.to_json

    parse_response(req)
  end

  def parse_response(request)
    res = @http.request(request)
    JSON.parse(res.body) unless res.body.empty?
  end

  def set_connection(uri)
    @http = Net::HTTP.new(uri.host, uri.port)
    @http.use_ssl = true if uri.instance_of?(URI::HTTPS)
  end
end
