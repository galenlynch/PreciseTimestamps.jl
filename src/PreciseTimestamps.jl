module PreciseTimestamps

import Base: isless, convert, show, -, +, ==
using Dates:
    AbstractDateTime,
    DateTime,
    DateFormat,
    Nanosecond,
    Microsecond,
    Millisecond,
    TimePeriod,
    @dateformat_str
using Printf: @sprintf
using TimeZones: localzone, Local
import TimeZones: ZonedDateTime
using IterTools: imap

export
    # Constants
    POSTGRES_DATE_FORMAT,
    PSQL_DATETIME_REG,
    JULIA_DT_REG,
    ## Time stuff
    FILE_DATEFORMAT,
    PreciseDateTime,
    RangeBound,
    TSRange,
    add_seconds,
    datevec_to_precisedatetime,
    duration,
    postgres_time_str,
    matlab_datestring,
    iso_fine_datestring,
    trailing_micros,
    dt_and_micros,
    ## Postgres
    postgres_time_str,
    parse_postgres_array,
    postgres_tsrange_to_datetime_micros,
    postgres_make_tsrange_str,
    postgres_tuple_list,
    postgres_tuple_rows,

    ## Misc array
    to_ntuple

to_ntuple(::Type{T}, args::Tuple) where {T} = map(x -> convert(T, x), args)
to_ntuple(::Type{T}, args...) where {T} = to_ntuple(T, args)

include("times.jl")
include("postgres.jl")
include("matlab.jl")

end
