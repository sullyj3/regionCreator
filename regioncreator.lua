-- In the selected track, create regions for each overlapping group of items

function compare_item_start_time(a, b)
  local a_start_pos = reaper.GetMediaItemInfo_Value(a, "D_POSITION")
  local b_start_pos = reaper.GetMediaItemInfo_Value(b, "D_POSITION")
  return a_start_pos <= b_start_pos
end

-- get track items in order of start time
function get_track_items(track)
  local num_items = reaper.CountTrackMediaItems(track)
  if num_items == 0 then
    return {}
  end

  local track_items = {}

  for i=0,num_items-1 do
    table.insert(track_items, reaper.GetTrackMediaItem(track, i))
  end
  table.sort(track_items, compare_item_start_time)

  return track_items
end


function main()
  local curr_track = reaper.GetSelectedTrack(0, 0)

  local track_items = get_track_items(curr_track)

  -- group together overlapping items
  local overlapping_groups = {{track_items[1]}}
  for i=2,#track_items do
    local curr_group = overlapping_groups[#overlapping_groups]

    -- determine whether curr_item overlaps prev_item
    local prev_item = curr_group[#curr_group]
    local prev_item_start = reaper.GetMediaItemInfo_Value(prev_item, "D_POSITION")
    local prev_item_end = prev_item_start + reaper.GetMediaItemInfo_Value(prev_item, "D_LENGTH")

    local curr_item = track_items[i]
    local curr_item_start = reaper.GetMediaItemInfo_Value(curr_item, "D_POSITION")

    if curr_item_start < prev_item_end then
      curr_group[#curr_group + 1] = curr_item
    else
      overlapping_groups[#overlapping_groups + 1] = {curr_item}
    end
  end

  -- create a region for each group
  for i, group in ipairs(overlapping_groups) do
    local group_start = reaper.GetMediaItemInfo_Value(group[1], "D_POSITION")
    local group_last_item = group[#group]
    local group_end = reaper.GetMediaItemInfo_Value(group_last_item, "D_POSITION") + reaper.GetMediaItemInfo_Value(group_last_item, "D_LENGTH")

    reaper.AddProjectMarker(0, true, group_start, group_end, "group " .. tostring(i), -1)
  end

end

main()
