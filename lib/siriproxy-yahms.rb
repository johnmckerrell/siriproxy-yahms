require 'cora'
require 'siri_objects'

#######
# mapme.at plugin, checks people into mapme.at simply by sending them to a mapme.at url
# 
# Remember to add other plugins to the "config.yml" file if you create them!
######

class SiriProxy::Plugin::YAHMS < SiriProxy::Plugin
  def initialize(config = {})
    @config = config
    #if you have custom configuration options, process them here!
    @mechanize = Mechanize.new
    @mechanize.get('http://yahms.net/') do |page|
      page.form_with( :action => "/user_session" ) do |form|
        form['user_session[login]'] = @config["username"]
        form['user_session[password]'] = @config["password"]
      end.submit
    end
  end

  def modify_input(input, switch, response, minutes = 15)
    Thread.new {
      begin
        @mechanize.get("http://yahms.net/base_stations/#{@config["base_station"]}") do |page|
          if switch.match(/off/i)
            page.form_with(:action => "/digital_outputs/#{input}/advance").submit
          else
            forms = page.forms_with(:action => "/digital_outputs/#{input}/plus_time")
            forms.each do |form|
              if form.minutes == minutes.to_s
                form.submit
              end
            end
          end
        end
        say response
        request_completed
      rescue Exception
        pp $!
        say "Sorry, I encountered an error."
        request_completed
      end
    }
  end

  listen_for /(I'm (cold|chilly))/i do
    modify_input(@config["heating"],"on", "I've turned the heating on, we'll have you warm in a jiffy.");
  end

  listen_for /(I'm (hot|warm))/i do
    modify_input(@config["heating"],"off", "I've advanced the heating, I hope that helps!");
  end

  listen_for /Turn the lights? (on|off)/i do |switch|
    modify_input(@config["light"],switch, "The light will be #{switch.downcase} in a moment.")
  end

end
