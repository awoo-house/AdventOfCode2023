using DelimitedFiles
using Pkg
Pkg.add("Pipe")
using Pipe
@enum Direction up down unknown

struct RowState
  direction::Direction
  last_value::Int
end

@enum Ret unsafe undefined

RetType = Union{Ret,RowState}

function is_valid_element(current_state::RowState, next_num::SubString{String})::RetType
  return current_state
end
function is_valid_element(current_state::Ret, next_num::SubString{String})::RetType
  return current_state
end
function is_valid_element(current_state::Ret, next_num::Int64)::RetType
  if current_state === unsafe
    return current_state
  end
  if current_state === undefined
    return RowState(unknown, next_num)
  end
end

function is_valid_element(current_state::RowState, next_num::Int64)::RetType
  if current_state.direction === up 
    if next_num <= current_state.last_value
      return unsafe
    elseif next_num - current_state.last_value > 3
      return unsafe
    else
      return RowState(up, next_num)
    end
  elseif current_state.direction === down 
    if next_num >= current_state.last_value
      return unsafe
    elseif  current_state.last_value - next_num > 3
      return unsafe
    else
      return RowState(down, next_num)
    end
  else # direction == unknown
    if next_num === current_state.last_value
      return unsafe
    elseif current_state.last_value - next_num > 3
      return unsafe
    elseif next_num - current_state.last_value > 3
      return unsafe
    elseif next_num > current_state.last_value
      return RowState(up, next_num)
    else
      return RowState(down, next_num)
    end
  end
end

# function is_valid_element(current_state, next_num)::RetType
#   return current_state
# end
function remove_specific(row, idx)
  return [row[i] for i in 1:length(row) if i != idx]
end

function try_removing_any_one_idx(row)
  inputs = [remove_specific(row, i) for i in 1:length(row)]
  initial_value::RetType = undefined
  @pipe inputs |>
    map(f -> foldl(is_valid_element, f; init=initial_value), _) |> 
    any(f -> typeof(f) === RowState, _)
  
end

show(try_removing_any_one_idx([1;5;3;4;8;6]))

function is_valid_row(row)
  initial_value::RetType = undefined
  result = foldl(is_valid_element, row; init=initial_value)
  if result === undefined || result === unsafe 
    return try_removing_any_one_idx(row)
  else
    return true
  end
end

function run() 
  data = readdlm("./inputs/2.txt")
  validity_mat = mapslices(is_valid_row, data; dims=2)
  validity_mat
end

a = run()

sum(a)