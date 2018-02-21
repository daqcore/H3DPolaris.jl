# This file is a part of H3DPolaris.jl, licensed under the MIT License (MIT).


struct PolarisEvents
    evtno::Vector{Int32}    # Event number
    ts_s::Vector{Int32}     # Event time, seconds
    ts_ms::Vector{Int32}    # Event time, milliseconds
    nhits::Vector{Int32}    # Detector number
end

export PolarisEvents

PolarisEvents() = PolarisEvents(
    Vector{Int32}(), Vector{Int32}(), Vector{Int32}(),
    Vector{Int32}()
)



struct PolarisHits
    evtno::Vector{Int32}    # Event number
    ts_s::Vector{Int32}     # Event time, seconds
    ts_ms::Vector{Int32}    # Event time, milliseconds
    detno::Vector{Int32}    # Detector number
    x::Vector{Int32}        # Position in µm,
    y::Vector{Int32}        # Position in µm,
    z::Vector{Int32}        # Position in µm,
    edep::Vector{Int32}     # Energy deposition in eV
end

export PolarisHits

PolarisHits() = PolarisHits(
    Vector{Int32}(), Vector{Int32}(), Vector{Int32}(),
    Vector{Int32}(), Vector{Int32}(), Vector{Int32}(),
    Vector{Int32}(), Vector{Int32}()
)



struct PolarisData
    events::PolarisEvents
    hits::PolarisHits
end

export PolarisData

PolarisData() = PolarisData(PolarisEvents(), PolarisHits())



function Base.read!(input::IO, data::PolarisData)
    events = data.events
    hits = data.hits

    try
        evtno = if !isempty(data.events.evtno)
            last(data.events.evtno) + 1
        else
            one(eltype(data.events.evtno))
        end

        while !eof(input)
            evthdr = read(input, PolarisEventHeader)
            evtno += 1

            for i in 1:evthdr.nhits
                hit = read(input, PolarisHit)
                push!(hits.evtno, evtno)
                push!(hits.ts_s, evthdr.ts_s)
                push!(hits.ts_ms, evthdr.ts_ms)
                push!(hits.detno, hit.detno)
                push!(hits.x, hit.x)
                push!(hits.y, hit.y)
                push!(hits.z, hit.z)
                push!(hits.edep, hit.edep)
            end

            push!(events.evtno, evtno)
            push!(events.ts_s, evthdr.ts_s)
            push!(events.ts_ms, evthdr.ts_ms)
            push!(events.nhits, evthdr.nhits)
        end
    catch err
        if isa(err, EOFError)
            info("Input was truncated.")
        else
            rethrow()
        end
    end
    data
end


Base.read(input::IO, ::Type{PolarisData}) = read!(input, PolarisData())


function Base.read(filename::AbstractString, ::Type{PolarisData})
    open(CompressedFile(filename)) do input
        read(input, PolarisData)
    end
end