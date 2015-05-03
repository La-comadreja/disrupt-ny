require_relative './distance_evaluator'

describe Object do
  let(:new_event) {
    {
      'subject' => 'hackathon',
      'location' => 'Columbia University, New York, NY',
      'start' => '2015-05-03T20:00:00',
      'end' => '2015-05-03T21:00:00'
    }
  }
  let(:nearby_events) {
    {
      'value' => [
        {
          'Location' => {
            'Coordinates' => {
              'Latitude' => 40.780339,
              'Longitude' => -73.980340
            }
          },
          'Start' => '2015-05-03T13:00:00',
          'End' => '2015-05-03T14:00:00'
        },
        {
          'Location' => {
            'Coordinates' => {
              'Latitude' => 41.292566,
              'Longitude' => -74.078887
            }
          },
          'Start' => '2015-05-03T19:00:00',
          'End' => '2015-05-03T19:45:00'
        },
        {
          'Location' => {
            'Coordinates' => {
              'Latitude' => 41.292566,
              'Longitude' => -74.078887
            }
          },
          'Start' => '2015-05-03T21:15:00',
          'End' => '2015-05-03T22:00:00'
        },
        {
          'Location' => {
            'Coordinates' => {
              'Latitude' => 40.780339,
              'Longitude' => -73.980340
            }
          },
          'Start' => '2015-05-04T00:00:00',
          'End' => '2015-05-04T01:00:00'
        }
      ]
    }
  }
  let(:conflicts) { described_class.new.send(:check_for_conflicts_in, nearby_events, new_event) }

  it 'does not flag non-conflicting events' do
    expect(conflicts =~ /40\.780339/).to be nil
  end

  it 'flags conflicting events' do
    expect(conflicts =~ /41\.292566/).to be_an_instance_of Fixnum
  end
end
