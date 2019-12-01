function dump(o)
  if type(o) == 'table' then
    local s = '{ '
    for k,v in pairs(o) do
       if type(k) ~= 'number' then k = '"'..k..'"' end
       s = s .. '['..k..'] = ' .. dump(v) .. ','
    end
    return s .. '} '
  else
    return tostring(o)
  end
end

function get_count_of_table(table_data)
  local count = 0
  for _ in pairs(table_data) do count = count + 1 end
  return count;
end

return {
  dump = dump,
  get_count_of_table = get_count_of_table
};