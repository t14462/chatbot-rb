function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end
 
 
 
local p = {}
 
function p.chatlog(frame)
  qwert = '<table class="ChatLog" width="100%">'
 
  for i = 1, tablelength(frame.args), 4 do
    qwert = qwert .. '<tr><td><span><span>[' .. (frame.args[i] or "") .. ']</span><span style="color:#' .. (frame.args[i+1] or "999") .. '">' .. (frame.args[i+2] or "") .. '</span></span><pre>' .. (frame.args[i+3] or ""):gsub(' ',' ') .. '</pre></td></tr>'
  end
 
  return qwert .. '</table>'
end
 
return p
