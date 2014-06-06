
using React
using JSON


const react_js = readall(joinpath(Pkg.dir("Interact"), "data", "react.min.js"))
#const transform_js = readall(joinpath(Pkg.dir("Interact"), "data", "JSXTransformer.min.js"))

# Include the the d3 javascript library
function prepare_display(d::Display)
    display(d, "text/html", """<script charset="utf-8">$(react_js)</script>""")
end

try
    display("text/html", """<script charset="utf-8">$(react_js)</script>""")
catch
end


abstract InputWidget{T}  # A widget that takes input of type T


type Slider{T <: Number} <: InputWidget{T}
    label :: String
    value :: T
    min   :: T
    max   :: T
    step  :: T
end


type Checkbox <: InputWidget{Bool}
    label :: String
    value :: Bool
end


type ToggleButton <: InputWidget{Symbol}
    label :: String
    value   :: Input{Symbol}
    options :: (Symbol, Symbol)
end


type Button <: InputWidget{()}
    label :: String
    value :: ()
end


type Text{T} <: InputWidget{T}
    label :: String
    value :: T
end


type Textarea{String} <: InputWidget{String}
    label :: String
    value :: String
end


type NumberText{T <: Number} <: InputWidget{T}
    label :: String
    value :: T
    range :: (T, T)
end


type RadioButtons <: InputWidget{Symbol}
    label :: String
    value :: Symbol
    options :: Vector{Symbol}
end


type Dropdown <: InputWidget{Symbol}
    label :: String
    value :: Symbol
    options :: Vector{Symbol}
end


type HTML <: InputWidget{String}
    label :: String
    value :: String
end


type Latex <: InputWidget{String}
    label :: String
    value :: String
end


function parse{T}(msg, ::InputWidget{T})
    # Should return a value of type T, by default
    # msg itself is assumed to be the value.
    return msg :: T
end

# Should we enforce a one-to-one mapping?
# Having multiple inputs might allow for unnecessarily complex stateful code?
const inputs = Dict{InputWidget, Set{Input}}()


function attach!{T}(widget :: InputWidget{T}, input :: Input{T})
    if ~haskey(inputs, widget)
        inputs[widget] = Set{Input}()
    end
    push!(inputs[widget], input)
    return nothing
end


function detach!{T}(widget :: InputWidget{T}, input :: Input{T})
    if haskey(inputs, widget)
        try
            pop!(inputs[widget], input)
        catch
        end
    end
end


function detach!{T}(widget :: InputWidget{T})
    if haskey(inputs, widget)
        empty!(inputs[widget])
    end
end


function detach!{T}(input :: Input{T})
    map((w, set) -> detach(w, input), inputs)
end


function recv{T}(widget :: InputWidget{T}, value :: T)
    # Hand-off received value to the signal graph
    if haskey(inputs, widget)
        map(input -> push!(input, value), inputs[widget])
    else
        warn("Received an update for a widget with no attached Input")
    end
end

uuid4() = string(Base.Random.uuid4())

const id_to_widget = Dict{String, InputWidget}()
const widget_to_id = Dict{InputWidget, String}()

function register_widget(w :: InputWidget)
    if haskey(widget_to_id, w)
        return widget_to_id[w]
    else
        id = string(uuid4())
        widget_to_id[w] = id
        id_to_widget[id] = w
        return id
    end        
end

function get_widget(id :: String)
    if haskey(id_to_widget, id)
        return id_to_widget[id]
    else
        warn("Widget with id $(id) does not exist.")
    end
end