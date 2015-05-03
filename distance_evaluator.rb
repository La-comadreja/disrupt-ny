require 'sinatra'
require 'thin'
require 'rest_client'

set :server, 'thin'

get '/' do
  event = params[:event]
  nearby_events = find_nearby_events(event)
  #event_list = '{"events": [{"address": "Columbia University, NY", "event_start": "7:00 PM", "event_end": "8:00 PM"}, {"address": "34 Sidney Place, Brooklyn, NY", "event_start": "8:30 PM", "event_end": "9:00 PM"}]}'
  #check_for_conflicts_in(event_list)
end

ESRI_TOKEN = 'L-cMHLjxYWKHH5hByflVAuJp8XTqmsXo0TL0OhVP9cbKqfiX8PGoxZcK59k-rMGczv9HhV3VCGT70qXgq6sv8HnMl2SxH5HMnXfKjL3YzOa2sK_Vo4tOXzzrn2ME55g1Pgxb8-FgAjWKaF5f93fkrg..'
OUTLOOK_AUTH = 'Basic aXZhbkB0aGVtd29ya3Mub25taWNyb3NvZnQuY29tOlI1a2g1ZHI1'

def find_nearby_events(param)
  search_start = (DateTime.parse(JSON.parse(param)['start']) - 1).to_s.split('+').first
  search_end = (DateTime.parse(JSON.parse(param)['end']) + 1).to_s.split('+').first
  resource = RestClient::Resource.new(outlook_rest_url(search_start, search_end))
  response = JSON.parse(resource.get(Authorization: OUTLOOK_AUTH))
end

def check_for_conflicts_in(event_list, previous = false)
  events = JSON.parse(event_list)['events']
  origin = events.first
  origin_coords = geocode(origin['address'])
  origin_end_time = DateTime.parse("2015-05-03T#{origin['event_end']}")
  destinations = events[1..-1]
  conflicts = []
  destinations.each do |destination|
    destination_coords = geocode(destination['address'])
    destination_start_time = DateTime.parse("2015-05-03T#{destination['event_start']}")
    time_between_events = ((destination_start_time - origin_end_time) * 24 * 60).to_i
    travel_time = route([origin_coords, destination_coords])
    conflicts.push(destination) if time_between_events < travel_time
  end
  { subsequent: conflicts }
end

def outlook_rest_url(search_start, search_end)
  "https://outlook.office365.com/api/v1.0/me/calendarview?startDateTime=#{search_start}Z&endDateTime=#{search_end}Z"
end

def geocode(address)
  address = address.gsub(' ', '+')
  response = RestClient.get("http://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer/find?text=#{address}&f=json")
  json = JSON.parse(response)
  coords = json['locations'].first['feature']['geometry']
  coords.values.join(',')
end

def route(endpoints)
  response = RestClient.get("http://route.arcgis.com/arcgis/rest/services/World/Route/NAServer/Route_World/solve?token=#{ESRI_TOKEN}&stops=#{endpoints.join(';')}&f=json")
  # JSON.parse(response)['directions'].first['features']
  JSON.parse(response)['routes']['features'].first['attributes']['Total_TravelTime'].to_i + 3
end
