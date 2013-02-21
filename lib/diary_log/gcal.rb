# -*- coding: utf-8 -*-

# Initialize the client & Google+ API
require 'google/api_client'
require 'json'

module DiaryLog
  class Gcal
    class Storage
      def initialize(options = {})
        @options = options
        unless File.exists?(@options[:path])
          dir = File.dirname(@options[:path])
          unless File.exists?(dir)
            Dir::mkdir(dir)
          end
        end
      end
      def load
        unless File.exists?(@options[:path])
          return nil
        end
        return ::JSON.parse(File.open(@options[:path]).read.to_s)
      end
      def save(data)
        File.open(@options[:path], 'w') do |f|
          f.write JSON.generate(data)
        end
      end
    end

    def initialize(options)
      @client = Google::APIClient.new(:application_name => 'diary_log', :application_version => '0.1')
      auth = @client.authorization
      # Initialize OAuth 2.0 client
      auth.client_id = options[:client_id]
      auth.client_secret = options[:client_secret]
      
      auth.redirect_uri = 'urn:ietf:wg:oauth:2.0:oob'

      auth.scope = 'https://www.googleapis.com/auth/calendar'

      storage = Storage.new(:path => options[:basepath] + '/tmp/access_token.json')
      access_token = storage.load

      if access_token && !access_token['access_token'].nil?
        auth.access_token = access_token['access_token']

        if !access_token['refresh_token'].nil?
          auth.refresh_token = access_token['refresh_token']
        end

        if auth.expired?
          access_token = auth.fetch_access_token!
          storage.save(access_token)
        end
      else
        puts ""
        puts "Please open this url and paste authorization code to below."
        puts ""
        puts "    " + auth.authorization_uri

        print "> "
        line = STDIN.gets

        auth.code = line.strip
        access_token = auth.fetch_access_token!
        storage.save(access_token)
      end

    end
    
    # Return Google::APIClient::Schema::Calendar::V3::Event
    def create_event(pattern, event)
      calendar_id = pattern.params[:calendar]
      if calendar_id.nil?
        return
      end
      
      # 重複してないか調べる
      events = list_events(calendar_id, event.start_time, event.end_time)
      
      if events.size > 0
#        puts "The event #{event.end_record.desc} has already created."
        return false
      end
      
      g_event = {
        'summary' => event.title,
        'start' => {
          'dateTime' => event.start_time.to_datetime.rfc3339,
        },
        'end' => {
          'dateTime' => event.end_time.to_datetime.rfc3339
        },
        'description' => event.end_record.desc
      }
      @client.execute(
        :api_method => service.events.insert,
        :parameters => {'calendarId' => calendar_id},
        :body => JSON.dump(g_event),
        :headers => {'Content-Type' => 'application/json'}
      )
    end
    
    # Return Array<Google::APIClient::Schema::Calendar::V3::Event>
    def list_events(calendar_id, from, to, exclude_all_day = true)
      params = {
        'calendarId' => calendar_id,
        'timeMin' => from.to_datetime.rfc3339,
        'timeMax' => to.to_datetime.rfc3339,
        'maxResults' => 20
      }
      
      page_token = nil
      result = @client.execute(
        :api_method => service.events.list,
        :parameters => params
      )

      events = []
      while true
        events.concat(result.data.items)
        
        if !(page_token = result.data.next_page_token)
          break
        end
        
        result = result = @client.execute(
          :api_method => service.events.list,
          :parameters => params.merge({'pageToken' => page_token})
        )
      end
      if exclude_all_day
#        events.reject!{|e| e['start']['datetime'].nil? || e['end']['datetime'].nil? }
        events.reject!{|e| e.start.date_time.nil? }
      end
      #pp events
      
      return events
    end
    
    protected
    def service
      @client.discovered_api('calendar', 'v3')
    end
  end
end
