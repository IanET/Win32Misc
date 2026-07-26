
# TODO
# - Support different types of layout

@kwdef struct StarSize
    val::Int = 0
end

Base.Int(s::StarSize) = s.val
Base.:(+)(x::StarSize, y::StarSize) = StarSize(Int(x) + Int(y))

macro star_str(s) parse(Int, s) |> StarSize end
macro ★_str(s) parse(Int, s) |> StarSize end

const IntOrStarSize = Union{Int, StarSize}

@kwdef mutable struct GridLayout
    grid::Matrix{Int} = Matrix{Int}(undef, 0, 0)
    rowHeights::Vector{IntOrStarSize} = []
    colWidths::Vector{IntOrStarSize} = []
end

function GridLayout(grid::Matrix{Int})
    rows, cols = size(grid)
    rowheights = [StarSize(1) for _ in 1:rows]
    colwidths = [StarSize(1) for _ in 1:cols]
    return GridLayout(grid, rowheights, colwidths)
end
GridLayout(v::Vector{Int}) = GridLayout(reshape(v, 1, length(v)))

function count_sizes(sizes::Vector{IntOrStarSize})
    stars = 0
    fixed = 0
    for size in sizes
        if size isa StarSize
            stars += Int(size)
        else
            fixed += size
        end
    end
    return stars, fixed
end

# Returns Dict{id => (x, y, w, h)} for the given parent size and grid layout.
# Rowspan/colspan: same id in multiple cells → union of all covered cells.
# Negative ids (padding) are included in the result and can be ignored by callers.
function computeLayout(W::Int, H::Int, gl::GridLayout)::Dict{Int, NTuple{4,Int}}
    gridrows, gridcols = size(gl.grid)
    @assert gridrows == length(gl.rowHeights) "Number of rows in matrix and rowHeights must match"
    @assert gridcols == length(gl.colWidths) "Number of columns in matrix and colWidths must match"

    hstars, hfixed = count_sizes(gl.rowHeights)
    wstars, wfixed = count_sizes(gl.colWidths)
    hspace = max(0, H - hfixed)
    wspace = max(0, W - wfixed)
    starh = hstars != 0 ? hspace ÷ hstars : 0
    starw = wstars != 0 ? wspace ÷ wstars : 0
    hrem = hstars != 0 ? hspace % hstars : 0
    wrem = wstars != 0 ? wspace % wstars : 0
    last_star_row = findlast(s -> s isa StarSize, gl.rowHeights)
    last_star_col = findlast(s -> s isa StarSize, gl.colWidths)

    # idrects stored as (left, top, right, bottom)
    idrects = Dict{Int, NTuple{4,Int}}()
    y = 0
    for i in 1:gridrows
        x = 0
        rh = gl.rowHeights[i]
        h = rh isa StarSize ? Int(rh) * starh + (i == last_star_row ? hrem : 0) : rh
        for j in 1:gridcols
            cw = gl.colWidths[j]
            w = cw isa StarSize ? Int(cw) * starw + (j == last_star_col ? wrem : 0) : cw
            id = gl.grid[i, j]
            cell = (x, y, x + w, y + h)
            cur = get(idrects, id, cell)
            idrects[id] = (min(cur[1], cell[1]), min(cur[2], cell[2]), max(cur[3], cell[3]), max(cur[4], cell[4]))
            x += w
        end
        y += h
    end

    return Dict(id => (l, t, r - l, b - t) for (id, (l, t, r, b)) in idrects)
end

setRowHeights(gl::GridLayout, rowHeights::Vector{IntOrStarSize}) = gl.rowHeights = rowHeights
setRowHeights(gl::GridLayout, rowheights::Vector{Any}) = setRowHeights(gl, convert(Array{IntOrStarSize,1}, rowheights))
setColWidths(gl::GridLayout, colWidths::Vector{IntOrStarSize}) = gl.colWidths = colWidths
setColWidths(gl::GridLayout, colWidths::Vector{Any}) = setColWidths(gl, convert(Array{IntOrStarSize,1}, colWidths))
