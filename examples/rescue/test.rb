require 'rubygems'
require 'pp'
require 'active_support'

class RescueHash < Hash
  def self::new_from_obj(obj)
    RescueHash.new.merge(obj)
  end

  def value(key)
    results = []
    self.each do |k,v|
      results << v.value(key) if v.class == RescueHash
      results << v if k == key.to_sym
    end
    results.length != 1 ? results.flatten : results[0]
  end

  def to_json(options = nil) #:nodoc:
    hash = as_json(options)

    result = '{ "!map:RescueHash": {'
    result << hash.map do |key, value|
      "#{ActiveSupport::JSON.encode(key.to_s)}:#{ActiveSupport::JSON.encode(value, options)}"
    end * ','
    result << '}}'
  end

  def as_json(options = nil) #:nodoc:
    if options
      if attrs = options[:except]
        except(*Array.wrap(attrs))
      elsif attrs = options[:only]
        slice(*Array.wrap(attrs))
      else
        self
      end
    else
      self
    end
  end
end

module ActiveSupport
  module JSON
    class << self
      def translate_json_objects(obj)
        res = nil
        case obj
          when Array
            res = Array.new
            obj.each do |e|
              res << translate_json_objects(e)
            end
          when Hash
            if obj.length == 1 && obj.keys.first =~ /!map:([A-Z][a-zA-Z0-9_]*)/
              newobj = eval($1)
              p obj[obj.keys.first]
              res = newobj.new_from_obj(translate_json_objects(obj[obj.keys.first]))
            else  
              res = Hash.new
              obj.each do |k,v|
                res[k] = translate_json_objects(v)
              end
            end
          else
            res = obj
        end
        res
      end
      def decode_translate(json)
        translate_json_objects(decode(json))
      end
    end  
  end  
end  

x = RescueHash.new
x[:bla] = "bla"
x[:time] = Time.now
x[:nested] = RescueHash.new
x[:nested][:bli] = "bli"
x[:nested][:blu] = "blu"
y = ActiveSupport::JSON::encode(x)
puts y

z = ActiveSupport::JSON::decode(y)
pp z

a = ActiveSupport::JSON::decode_translate(y)
p a
puts a.class
puts a['nested'].class

hd ='{"!map:RescueHash": {"http://localhost:9290/groups/CinemasReal//Soap/LugnerCityKino":{ "!map:RescueHash": {"list":"\u003Clist_of_shows\u003E\n  \u003Cshow\u003E\n    \u003Ccinema_uri\u003Ehttp://localhost:9290/groups/CinemasReal/Soap/LugnerCityKino\u003C/cinema_uri\u003E\n    \u003Cshow_id\u003E131516\u003C/show_id\u003E\n    \u003Ctitle\u003EEclipse - Biss zum Abendrot\u003C/title\u003E\n    \u003Cdate\u003E22.07.2010\u003C/date\u003E\n    \u003Ctime\u003E17:00\u003C/time\u003E\n    \u003Chall\u003E2\u003C/hall\u003E\n  \u003C/show\u003E\n  \u003Cshow\u003E\n    \u003Ccinema_uri\u003Ehttp://localhost:9290/groups/CinemasReal/Soap/LugnerCityKino\u003C/cinema_uri\u003E\n    \u003Cshow_id\u003E131656\u003C/show_id\u003E\n    \u003Ctitle\u003EEclipse - Biss zum Abendrot\u003C/title\u003E\n    \u003Cdate\u003E22.07.2010\u003C/date\u003E\n    \u003Ctime\u003E18:00\u003C/time\u003E\n    \u003Chall\u003E6\u003C/hall\u003E\n  \u003C/show\u003E\n  \u003Cshow\u003E\n    \u003Ccinema_uri\u003Ehttp://localhost:9290/groups/CinemasReal/Soap/LugnerCityKino\u003C/cinema_uri\u003E\n    \u003Cshow_id\u003E131859\u003C/show_id\u003E\n    \u003Ctitle\u003EEclipse - Biss zum Abendrot\u003C/title\u003E\n    \u003Cdate\u003E22.07.2010\u003C/date\u003E\n    \u003Ctime\u003E20:00\u003C/time\u003E\n    \u003Chall\u003E2\u003C/hall\u003E\n  \u003C/show\u003E\n  \u003Cshow\u003E\n    \u003Ccinema_uri\u003Ehttp://localhost:9290/groups/CinemasReal/Soap/LugnerCityKino\u003C/cinema_uri\u003E\n    \u003Cshow_id\u003E131663\u003C/show_id\u003E\n    \u003Ctitle\u003EEclipse - Biss zum Abendrot\u003C/title\u003E\n    \u003Cdate\u003E22.07.2010\u003C/date\u003E\n    \u003Ctime\u003E20:30\u003C/time\u003E\n    \u003Chall\u003E6\u003C/hall\u003E\n  \u003C/show\u003E\n  \u003Cshow\u003E\n    \u003Ccinema_uri\u003Ehttp://localhost:9290/groups/CinemasReal/Soap/LugnerCityKino\u003C/cinema_uri\u003E\n    \u003Cshow_id\u003E131523\u003C/show_id\u003E\n    \u003Ctitle\u003EEclipse - Biss zum Abendrot\u003C/title\u003E\n    \u003Cdate\u003E22.07.2010\u003C/date\u003E\n    \u003Ctime\u003E22:45\u003C/time\u003E\n    \u003Chall\u003E2\u003C/hall\u003E\n  \u003C/show\u003E\n\u003C/list_of_shows\u003E","status":null}},"list_shows":[],"http://localhost:9290/groups/CinemasReal//REST/DonauPlexx":{ "!map:RescueHash": {"list":"\u003Clist_of_shows\u003E\n  \u003Cshow\u003E\n    \u003Ccinema_uri\u003Ehttp://localhost:9290/groups/CinemasReal/REST/DonauPlexx\u003C/cinema_uri\u003E\n    \u003Cshow_id\u003E/content/ticketing/ticketing.aspx?eventid=35524335\u0026amp;bu=http%3a%2f%2fwww.cineplexx.at%2fcontent%2fkinos%2fkinoprogramm.aspx%3fid%3d346%26datum%3d22.07.2010%26uhrzeit%3d00%253A00%253A00%26version%3d\u003C/show_id\u003E\n    \u003Ctitle\u003EEclipse - Biss zum Abendrot\u003C/title\u003E\n    \u003Cdate\u003E2010-07-22\u003C/date\u003E\n    \u003Ctime\u003E17:40\u003C/time\u003E\n    \u003Chall\u003ESaal 1\u003C/hall\u003E\n  \u003C/show\u003E\n  \u003Cshow\u003E\n    \u003Ccinema_uri\u003Ehttp://localhost:9290/groups/CinemasReal/REST/DonauPlexx\u003C/cinema_uri\u003E\n    \u003Cshow_id\u003E/content/ticketing/ticketing.aspx?eventid=35524353\u0026amp;bu=http%3a%2f%2fwww.cineplexx.at%2fcontent%2fkinos%2fkinoprogramm.aspx%3fid%3d346%26datum%3d22.07.2010%26uhrzeit%3d00%253A00%253A00%26version%3d\u003C/show_id\u003E\n    \u003Ctitle\u003EEclipse - Biss zum Abendrot\u003C/title\u003E\n    \u003Cdate\u003E2010-07-22\u003C/date\u003E\n    \u003Ctime\u003E20:30\u003C/time\u003E\n    \u003Chall\u003ESaal 1\u003C/hall\u003E\n  \u003C/show\u003E\n  \u003Cshow\u003E\n    \u003Ccinema_uri\u003Ehttp://localhost:9290/groups/CinemasReal/REST/DonauPlexx\u003C/cinema_uri\u003E\n    \u003Cshow_id\u003E/content/ticketing/ticketing.aspx?eventid=35524324\u0026amp;bu=http%3a%2f%2fwww.cineplexx.at%2fcontent%2fkinos%2fkinoprogramm.aspx%3fid%3d346%26datum%3d22.07.2010%26uhrzeit%3d00%253A00%253A00%26version%3d\u003C/show_id\u003E\n    \u003Ctitle\u003EEclipse - Biss zum Abendrot\u003C/title\u003E\n    \u003Cdate\u003E2010-07-22\u003C/date\u003E\n    \u003Ctime\u003E15:30\u003C/time\u003E\n    \u003Chall\u003ESaal 10\u003C/hall\u003E\n  \u003C/show\u003E\n  \u003Cshow\u003E\n    \u003Ccinema_uri\u003Ehttp://localhost:9290/groups/CinemasReal/REST/DonauPlexx\u003C/cinema_uri\u003E\n    \u003Cshow_id\u003E/content/ticketing/ticketing.aspx?eventid=35524342\u0026amp;bu=http%3a%2f%2fwww.cineplexx.at%2fcontent%2fkinos%2fkinoprogramm.aspx%3fid%3d346%26datum%3d22.07.2010%26uhrzeit%3d00%253A00%253A00%26version%3d\u003C/show_id\u003E\n    \u003Ctitle\u003EEclipse - Biss zum Abendrot\u003C/title\u003E\n    \u003Cdate\u003E2010-07-22\u003C/date\u003E\n    \u003Ctime\u003E18:15\u003C/time\u003E\n    \u003Chall\u003ESaal 10\u003C/hall\u003E\n  \u003C/show\u003E\n  \u003Cshow\u003E\n    \u003Ccinema_uri\u003Ehttp://localhost:9290/groups/CinemasReal/REST/DonauPlexx\u003C/cinema_uri\u003E\n    \u003Cshow_id\u003E/content/ticketing/ticketing.aspx?eventid=35524356\u0026amp;bu=http%3a%2f%2fwww.cineplexx.at%2fcontent%2fkinos%2fkinoprogramm.aspx%3fid%3d346%26datum%3d22.07.2010%26uhrzeit%3d00%253A00%253A00%26version%3d\u003C/show_id\u003E\n    \u003Ctitle\u003EEclipse - Biss zum Abendrot\u003C/title\u003E\n    \u003Cdate\u003E2010-07-22\u003C/date\u003E\n    \u003Ctime\u003E21:00\u003C/time\u003E\n    \u003Chall\u003ESaal 10\u003C/hall\u003E\n  \u003C/show\u003E\n  \u003Cshow\u003E\n    \u003Ccinema_uri\u003Ehttp://localhost:9290/groups/CinemasReal/REST/DonauPlexx\u003C/cinema_uri\u003E\n    \u003Cshow_id\u003E/content/ticketing/ticketing.aspx?eventid=35524332\u0026amp;bu=http%3a%2f%2fwww.cineplexx.at%2fcontent%2fkinos%2fkinoprogramm.aspx%3fid%3d346%26datum%3d22.07.2010%26uhrzeit%3d00%253A00%253A00%26version%3d\u003C/show_id\u003E\n    \u003Ctitle\u003EEclipse - Biss zum Abendrot\u003C/title\u003E\n    \u003Cdate\u003E2010-07-22\u003C/date\u003E\n    \u003Ctime\u003E17:00\u003C/time\u003E\n    \u003Chall\u003ESaal 2\u003C/hall\u003E\n  \u003C/show\u003E\n  \u003Cshow\u003E\n    \u003Ccinema_uri\u003Ehttp://localhost:9290/groups/CinemasReal/REST/DonauPlexx\u003C/cinema_uri\u003E\n    \u003Cshow_id\u003E/content/ticketing/ticketing.aspx?eventid=35524347\u0026amp;bu=http%3a%2f%2fwww.cineplexx.at%2fcontent%2fkinos%2fkinoprogramm.aspx%3fid%3d346%26datum%3d22.07.2010%26uhrzeit%3d00%253A00%253A00%26version%3d\u003C/show_id\u003E\n    \u003Ctitle\u003EEclipse - Biss zum Abendrot\u003C/title\u003E\n    \u003Cdate\u003E2010-07-22\u003C/date\u003E\n    \u003Ctime\u003E20:00\u003C/time\u003E\n    \u003Chall\u003ESaal 2\u003C/hall\u003E\n  \u003C/show\u003E\n  \u003Cshow\u003E\n    \u003Ccinema_uri\u003Ehttp://localhost:9290/groups/CinemasReal/REST/DonauPlexx\u003C/cinema_uri\u003E\n    \u003Cshow_id\u003E/content/ticketing/ticketing.aspx?eventid=35524365\u0026amp;bu=http%3a%2f%2fwww.cineplexx.at%2fcontent%2fkinos%2fkinoprogramm.aspx%3fid%3d346%26datum%3d22.07.2010%26uhrzeit%3d00%253A00%253A00%26version%3d\u003C/show_id\u003E\n    \u003Ctitle\u003EEclipse - Biss zum Abendrot\u003C/title\u003E\n    \u003Cdate\u003E2010-07-22\u003C/date\u003E\n    \u003Ctime\u003E16:30\u003C/time\u003E\n    \u003Chall\u003ESaal 6\u003C/hall\u003E\n  \u003C/show\u003E\n  \u003Cshow\u003E\n    \u003Ccinema_uri\u003Ehttp://localhost:9290/groups/CinemasReal/REST/DonauPlexx\u003C/cinema_uri\u003E\n    \u003Cshow_id\u003E/content/ticketing/ticketing.aspx?eventid=35524366\u0026amp;bu=http%3a%2f%2fwww.cineplexx.at%2fcontent%2fkinos%2fkinoprogramm.aspx%3fid%3d346%26datum%3d22.07.2010%26uhrzeit%3d00%253A00%253A00%26version%3d\u003C/show_id\u003E\n    \u003Ctitle\u003EEclipse - Biss zum Abendrot\u003C/title\u003E\n    \u003Cdate\u003E2010-07-22\u003C/date\u003E\n    \u003Ctime\u003E19:30\u003C/time\u003E\n    \u003Chall\u003ESaal 6\u003C/hall\u003E\n  \u003C/show\u003E\n\u003C/list_of_shows\u003E","status":200}},"http://localhost:9290/groups/CinemasReal//REST/AugeGottes":{ "!map:RescueHash": {"list":"\u003Clist_of_shows\u003E\n  \u003Cshow\u003E\n    \u003Ccinema_uri\u003Ehttp://localhost:9290/groups/CinemasReal/REST/AugeGottes\u003C/cinema_uri\u003E\n    \u003Cshow_id\u003E/content/ticketing/ticketing.aspx?eventid=35520623\u0026amp;bu=http%3a%2f%2fwww.cineplexx.at%2fcontent%2fkinos%2fkinoprogramm.aspx%3fid%3d6%26datum%3d22.07.2010%26uhrzeit%3d00%253A00%253A00%26version%3d\u003C/show_id\u003E\n    \u003Ctitle\u003EEclipse - Biss zum Abendrot\u003C/title\u003E\n    \u003Cdate\u003E2010-07-22\u003C/date\u003E\n    \u003Ctime\u003E16:00\u003C/time\u003E\n    \u003Chall\u003ESaal A\u003C/hall\u003E\n  \u003C/show\u003E\n  \u003Cshow\u003E\n    \u003Ccinema_uri\u003Ehttp://localhost:9290/groups/CinemasReal/REST/AugeGottes\u003C/cinema_uri\u003E\n    \u003Cshow_id\u003E/content/ticketing/ticketing.aspx?eventid=35520624\u0026amp;bu=http%3a%2f%2fwww.cineplexx.at%2fcontent%2fkinos%2fkinoprogramm.aspx%3fid%3d6%26datum%3d22.07.2010%26uhrzeit%3d00%253A00%253A00%26version%3d\u003C/show_id\u003E\n    \u003Ctitle\u003EEclipse - Biss zum Abendrot\u003C/title\u003E\n    \u003Cdate\u003E2010-07-22\u003C/date\u003E\n    \u003Ctime\u003E18:15\u003C/time\u003E\n    \u003Chall\u003ESaal A\u003C/hall\u003E\n  \u003C/show\u003E\n  \u003Cshow\u003E\n    \u003Ccinema_uri\u003Ehttp://localhost:9290/groups/CinemasReal/REST/AugeGottes\u003C/cinema_uri\u003E\n    \u003Cshow_id\u003E/content/ticketing/ticketing.aspx?eventid=35520625\u0026amp;bu=http%3a%2f%2fwww.cineplexx.at%2fcontent%2fkinos%2fkinoprogramm.aspx%3fid%3d6%26datum%3d22.07.2010%26uhrzeit%3d00%253A00%253A00%26version%3d\u003C/show_id\u003E\n    \u003Ctitle\u003EEclipse - Biss zum Abendrot\u003C/title\u003E\n    \u003Cdate\u003E2010-07-22\u003C/date\u003E\n    \u003Ctime\u003E20:30\u003C/time\u003E\n    \u003Chall\u003ESaal A\u003C/hall\u003E\n  \u003C/show\u003E\n\u003C/list_of_shows\u003E","status":200}},"http://localhost:9290/groups/CinemasReal//Soap/SCNHollywood":{ "!map:RescueHash": {"list":"\u003Clist_of_shows\u003E\n  \u003Cshow\u003E\n    \u003Ccinema_uri\u003Ehttp://localhost:9290/groups/CinemasReal/Soap/SCNHollywood\u003C/cinema_uri\u003E\n    \u003Cshow_id\u003E122389\u003C/show_id\u003E\n    \u003Ctitle\u003EEclipse DIGITAL\u003C/title\u003E\n    \u003Cdate\u003E22.07.2010\u003C/date\u003E\n    \u003Ctime\u003E20:00\u003C/time\u003E\n    \u003Chall\u003E4\u003C/hall\u003E\n  \u003C/show\u003E\n  \u003Cshow\u003E\n    \u003Ccinema_uri\u003Ehttp://localhost:9290/groups/CinemasReal/Soap/SCNHollywood\u003C/cinema_uri\u003E\n    \u003Cshow_id\u003E122304\u003C/show_id\u003E\n    \u003Ctitle\u003EEclipse\u003C/title\u003E\n    \u003Cdate\u003E22.07.2010\u003C/date\u003E\n    \u003Ctime\u003E15:00\u003C/time\u003E\n    \u003Chall\u003E1\u003C/hall\u003E\n  \u003C/show\u003E\n  \u003Cshow\u003E\n    \u003Ccinema_uri\u003Ehttp://localhost:9290/groups/CinemasReal/Soap/SCNHollywood\u003C/cinema_uri\u003E\n    \u003Cshow_id\u003E122308\u003C/show_id\u003E\n    \u003Ctitle\u003EEclipse\u003C/title\u003E\n    \u003Cdate\u003E22.07.2010\u003C/date\u003E\n    \u003Ctime\u003E17:30\u003C/time\u003E\n    \u003Chall\u003E1\u003C/hall\u003E\n  \u003C/show\u003E\n  \u003Cshow\u003E\n    \u003Ccinema_uri\u003Ehttp://localhost:9290/groups/CinemasReal/Soap/SCNHollywood\u003C/cinema_uri\u003E\n    \u003Cshow_id\u003E122315\u003C/show_id\u003E\n    \u003Ctitle\u003EEclipse\u003C/title\u003E\n    \u003Cdate\u003E22.07.2010\u003C/date\u003E\n    \u003Ctime\u003E20:30\u003C/time\u003E\n    \u003Chall\u003E1\u003C/hall\u003E\n  \u003C/show\u003E\n\u003C/list_of_shows\u003E","status":null}},"http://localhost:9290/groups/CinemasReal//REST/Apollo":{ "!map:RescueHash": {"list":"\u003Clist_of_shows\u003E\n  \u003Cshow\u003E\n    \u003Ccinema_uri\u003Ehttp://localhost:9290/groups/CinemasReal/REST/Apollo\u003C/cinema_uri\u003E\n    \u003Cshow_id\u003E/content/ticketing/ticketing.aspx?eventid=35524083\u0026amp;bu=http%3a%2f%2fwww.cineplexx.at%2fcontent%2fkinos%2fkinoprogramm.aspx%3fid%3d1%26datum%3d22.07.2010%26uhrzeit%3d00%253A00%253A00%26version%3d\u003C/show_id\u003E\n    \u003Ctitle\u003EEclipse - Biss zum Abendrot\u003C/title\u003E\n    \u003Cdate\u003E2010-07-22\u003C/date\u003E\n    \u003Ctime\u003E18:00\u003C/time\u003E\n    \u003Chall\u003ESaal 11\u003C/hall\u003E\n  \u003C/show\u003E\n  \u003Cshow\u003E\n    \u003Ccinema_uri\u003Ehttp://localhost:9290/groups/CinemasReal/REST/Apollo\u003C/cinema_uri\u003E\n    \u003Cshow_id\u003E/content/ticketing/ticketing.aspx?eventid=35524096\u0026amp;bu=http%3a%2f%2fwww.cineplexx.at%2fcontent%2fkinos%2fkinoprogramm.aspx%3fid%3d1%26datum%3d22.07.2010%26uhrzeit%3d00%253A00%253A00%26version%3d\u003C/show_id\u003E\n    \u003Ctitle\u003EEclipse - Biss zum Abendrot\u003C/title\u003E\n    \u003Cdate\u003E2010-07-22\u003C/date\u003E\n    \u003Ctime\u003E20:30\u003C/time\u003E\n    \u003Chall\u003ESaal 11\u003C/hall\u003E\n  \u003C/show\u003E\n  \u003Cshow\u003E\n    \u003Ccinema_uri\u003Ehttp://localhost:9290/groups/CinemasReal/REST/Apollo\u003C/cinema_uri\u003E\n    \u003Cshow_id\u003E/content/ticketing/ticketing.aspx?eventid=35524084\u0026amp;bu=http%3a%2f%2fwww.cineplexx.at%2fcontent%2fkinos%2fkinoprogramm.aspx%3fid%3d1%26datum%3d22.07.2010%26uhrzeit%3d00%253A00%253A00%26version%3d\u003C/show_id\u003E\n    \u003Ctitle\u003EEclipse - Biss zum Abendrot\u003C/title\u003E\n    \u003Cdate\u003E2010-07-22\u003C/date\u003E\n    \u003Ctime\u003E17:30\u003C/time\u003E\n    \u003Chall\u003ESaal 2\u003C/hall\u003E\n  \u003C/show\u003E\n  \u003Cshow\u003E\n    \u003Ccinema_uri\u003Ehttp://localhost:9290/groups/CinemasReal/REST/Apollo\u003C/cinema_uri\u003E\n    \u003Cshow_id\u003E/content/ticketing/ticketing.aspx?eventid=35524098\u0026amp;bu=http%3a%2f%2fwww.cineplexx.at%2fcontent%2fkinos%2fkinoprogramm.aspx%3fid%3d1%26datum%3d22.07.2010%26uhrzeit%3d00%253A00%253A00%26version%3d\u003C/show_id\u003E\n    \u003Ctitle\u003EEclipse - Biss zum Abendrot\u003C/title\u003E\n    \u003Cdate\u003E2010-07-22\u003C/date\u003E\n    \u003Ctime\u003E20:00\u003C/time\u003E\n    \u003Chall\u003ESaal 2\u003C/hall\u003E\n  \u003C/show\u003E\n  \u003Cshow\u003E\n    \u003Ccinema_uri\u003Ehttp://localhost:9290/groups/CinemasReal/REST/Apollo\u003C/cinema_uri\u003E\n    \u003Cshow_id\u003E/content/ticketing/ticketing.aspx?eventid=35524089\u0026amp;bu=http%3a%2f%2fwww.cineplexx.at%2fcontent%2fkinos%2fkinoprogramm.aspx%3fid%3d1%26datum%3d22.07.2010%26uhrzeit%3d00%253A00%253A00%26version%3d\u003C/show_id\u003E\n    \u003Ctitle\u003EEclipse - Biss zum Abendrot\u003C/title\u003E\n    \u003Cdate\u003E2010-07-22\u003C/date\u003E\n    \u003Ctime\u003E15:30\u003C/time\u003E\n    \u003Chall\u003ESaal 3\u003C/hall\u003E\n  \u003C/show\u003E\n\u003C/list_of_shows\u003E","status":200}}}}'
d = ActiveSupport::JSON::decode_translate(hd)

pp d.value('list')

