
# TODO
# - Support different types of layout

@kwdef struct StarSize
    val::Int = 0
end

Base.getindex(s::StarSize) = s.val
Base.Int(s::StarSize) = s[]
Base.:(+)(x::StarSize, y::StarSize) = StarSize(Int(x) + Int(y))

macro star_str(s) parse(Int, s) |> StarSize end
macro ★_str(s) parse(Int, s) |> StarSize end

const IntOrStarSize = Union{Int, StarSize}

@kwdef mutable struct GridLayout
    grid::Matrix{Int} = Matrix(undef, 0, 0)
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

union(rc1::RECT, rc2::RECT) = RECT(min(rc1.left, rc2.left), min(rc1.top, rc2.top), max(rc1.right, rc2.right), max(rc1.bottom, rc2.bottom))

function count(sizes::Vector{IntOrStarSize})
    stars = 0
    fixed = 0
    for size in sizes
        if size isa StarSize
            stars += size[]
        else
            fixed += size
        end
    end
    return stars, fixed
end

# Simple grid layout supporting pixel and star sizes for each row and column
# Rowspan and colspan supported by using the same id in multiple places (total size is union of all cells)
# Invalid control ids can be used for padding
function layout(hwnd::HWND, gl::GridLayout)
    rcparent_ref = RECT() |> Ref
    W32.GetClientRect(hwnd, rcparent_ref)
    rcparent = rcparent_ref[]
    gridrows, gridcols = size(gl.grid)

    @assert gridrows == length(gl.rowHeights) "Number of rows in matrix and rowHeights must match"
    @assert gridcols == length(gl.colWidths) "Number of columns in matrix and colWidths must match"

    # Measure 
    idrects = Dict{Int, RECT}()

    isstarsize(x) = x isa StarSize

    hstars, hfixed = count(gl.rowHeights)
    wstars, wfixed = count(gl.colWidths)

    starheight = hstars != 0 ? ((rcparent.bottom - rcparent.top) - hfixed) ÷ hstars : 0
    starwidth = wstars != 0 ? ((rcparent.right - rcparent.left) - wfixed) ÷ wstars : 0

    y = rcparent.top
    for i in 1:gridrows
        x = rcparent.left
        h = 0
        for j in 1:gridcols
            colwidth = gl.colWidths[j]
            rowheight = gl.rowHeights[i]
            w = colwidth isa StarSize ? Int(colwidth) * starwidth : colwidth
            h = rowheight isa StarSize ? Int(rowheight) * starheight : rowheight
            rcchild = RECT(x, y, x+w, y+h)
            id = gl.grid[i, j]
            rcchild = union(get(idrects, id, rcchild), rcchild)
            idrects[id] = rcchild
            x += w
        end
        y += h
    end

    # Arrange
    for id in keys(idrects)
        sz = idrects[id]
        child = W32.GetDlgItem(hwnd, id)
        if child != HWND(0)
            W32.SetWindowPos(child, HWND(0), sz.left, sz.top, sz.right-sz.left, sz.bottom-sz.top, W32.SWP_NOZORDER)
        end
    end

end

setRowHeights(gl::GridLayout, rowHeights::Vector{IntOrStarSize}) = gl.rowHeights = rowHeights
setRowHeights(gl::GridLayout, rowheights::Vector{Any}) = setRowHeights(gl, convert(Array{IntOrStarSize,1}, rowheights))
setColWidths(gl::GridLayout, colWidths::Vector{IntOrStarSize}) = gl.colWidths = colWidths
setColWidths(gl::GridLayout, colWidths::Vector{Any}) = setColWidths(gl, convert(Array{IntOrStarSize,1}, colWidths)) 
