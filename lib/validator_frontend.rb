require 'rack/request'

class ValidatorFrontend

  def initialize(filter = {})
    @filter = filter
    @ds = DB[:osm_errors].filter(@filter).select(:id, :type, :text).select_append{ st_asgeojson(geometry).as(:geometry) }.order(:source, :source_id)
  end

  def call(env)
    req = Rack::Request.new env

    build_response(req, build_data(req))
  end

  private

  def build_data(req)
    ds = @ds

    # Apply BBOX if present
    if has_bbox? req
      if bbox = build_bbox(req)
        ds = ds.where('geometry && ?::geography', bbox)
      else
        return "{\"error\": \"Invalid bbox\"}"
      end
    end

    # Calculate offset/limit values
    lim = (req[:limit] || 100).to_i
    off = (req[:offset] || 0).to_i

    # Build results from dataset
    build_results(ds.limit(lim, off), ds.count)
  end

  def build_results(ds, count)
    res = "{\"count\":#{count},\"results\":["

    ds.each do |r|
      res << "{\"type\":\"#{r[:type]}\",\"text\":\"#{r[:text].gsub('\\','\\\\').gsub('"','\\"')}\",\"geometry\":#{r[:geometry]}},"
    end

    res.chomp! ','
    res << "]}"
    res
  end

  def build_response(req, data)
    if req[:callback] # Is it JSONP?
      [200, {'Content-Type' => 'application/javascript'}, "#{req[:callback]}(#{data})"]
    else
      [200, {'Content-Type' => 'application/json'}, data]
    end
  end

  def has_bbox?(req)
    [:minlat, :maxlat, :minlon, :maxlat].any? {|key| req[key] }
  end

  def build_bbox(req)
    minlat = req[:minlat].to_f
    minlon = req[:minlon].to_f
    maxlat = req[:maxlat].to_f
    maxlon = req[:maxlon].to_f

    return nil if minlat >= maxlat || minlon >= maxlon

    "POLYGON((#{minlon} #{minlat},#{maxlon} #{minlat},#{maxlon} #{maxlat},#{minlon} #{maxlat},#{minlon} #{minlat}))"
  end

end
