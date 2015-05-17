require 'sinatra'
require 'thin'
require 'rest_client'
require 'json'

set :server, 'thin'

get '/' do
  event = params[:event]
  callback = params.delete('callback') # jsonp
  new_event = JSON.parse(event)
  nearby_events = find_nearby_events(new_event)
  json = check_for_conflicts_in(nearby_events, new_event)
  
  if callback
    content_type :js
    response = "#{callback}(#{json})"
  else
    content_type :json
    response = json
  end
  response
end

get '/order' do
  File.read('index.html')
end

get '/AppRead' do
  File.read('MailApp1/AppRead/Home/Home.html')
end

ESRI_CLIENT_ID = 'o7U4CF9NDgDtVryb'
ESRI_CLIENT_SECRET = 'f331ecdd0fe74a7a996ec514319578dc'
OUTLOOK_AUTH = 'Basic aXZhbkB0aGVtd29ya3Mub25taWNyb3NvZnQuY29tOlI1a2g1ZHI1'

def find_nearby_events(parsed_param)
  search_start = (DateTime.parse(parsed_param['start']) - 1).to_s.split('+').first
  search_end = (DateTime.parse(parsed_param['end']) + 1).to_s.split('+').first
  resource = RestClient::Resource.new(outlook_rest_url(search_start, search_end))
  JSON.parse(resource.get(Authorization: OUTLOOK_AUTH))
end

def check_for_conflicts_in(nearby_events, new_event)
  previous_conflicts = []
  subsequent_conflicts = []
  new_event_start = DateTime.parse(new_event['start'])
  new_event_end = DateTime.parse(new_event['end'])
  new_event_coords = geocode(new_event['location'])
  nearby_events['value'].each do |event|
    coords = event['Location']['Coordinates']
    old_event_coords = "#{coords['Longitude']},#{coords['Latitude']}"
    old_event_start = DateTime.parse(event['Start'])
    old_event_end = DateTime.parse(event['End'])
    if old_event_end <= new_event_start
      # If the previously scheduled event occurred earlier than the new event
      time_between_events = ((new_event_start - old_event_end) * 24 * 60).to_i
      previous_conflicts.push(event) if time_between_events < route([old_event_coords, new_event_coords])
    elsif new_event_end <= old_event_start
      # If the previously scheduled event occurred later than the new event
      time_between_events = ((old_event_start - new_event_end) * 24 * 60.to_i)
      subsequent_conflicts.push(event) if time_between_events < route([new_event_coords, old_event_coords])
    end
  end
  { events: { previous: previous_conflicts, subsequent: subsequent_conflicts } }.to_json
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
  response = RestClient.get("http://route.arcgis.com/arcgis/rest/services/World/Route/NAServer/Route_World/solve?token=#{esri_token}&stops=#{endpoints.join(';')}&f=json")
  JSON.parse(response)['routes']['features'].first['attributes']['Total_TravelTime'].to_i + 3
end

def esri_token
  getToken = Net::HTTP.post_form URI('https://www.arcgis.com/sharing/rest/oauth2/token'),
    f: 'json',
    client_id: ESRI_CLIENT_ID,
    client_secret: ESRI_CLIENT_SECRET,
    grant_type: 'client_credentials'
  JSON.parse(getToken.body)['access_token']
end
