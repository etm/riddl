class Float
  def round_prec(prec)
    p = 10**prec
    ((self * p).round).to_f / p
  end  
end  

def dms_to_deg(degrees,minutes,seconds)
  degrees + minutes/60 + seconds.to_f/3600
end

def deg_to_dms(degrees)
  raise "Input not negative" if degrees < 0

  degf = degrees
  degi = degf.to_i
  minf = 60 * (degf - degi)
  mini = minf.to_i
  secf = 60 * (minf - mini)
  
  secr = secf.round_prec(2)
  if secr == 60.0
    mini += 1
    secr = 0.0
  end  
  if mini == 60
    degi += 1
    mini = 0
  end

  [degi,mini,secr]
end


deg = dms_to_deg(48.00, 13.10, 0.00)
dms = deg_to_dms(deg)

p deg
p dms
