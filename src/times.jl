const FILE_DATEFORMAT = DateFormat("yyyy-mm-ddTHH-MM-SS")
const JULIA_DT_REG = r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}"

struct PreciseDateTime <: AbstractDateTime
    datetime::ZonedDateTime
    nanos::Nanosecond
end

PreciseDateTime(dt::ZonedDateTime) = PreciseDateTime(dt, Nanosecond(0))
PreciseDateTime(dt::ZonedDateTime, nanos::Real) =
    PreciseDateTime(dt) + Nanosecond(round(Int, nanos))
PreciseDateTime(dt::DateTime, args...) =
    PreciseDateTime(ZonedDateTime(dt, localzone()), args...)

function -(x::PreciseDateTime, y::PreciseDateTime)
    Millisecond(x.datetime - y.datetime).value * 1e-3 + (x.nanos - y.nanos).value * 1e-9
end

convert(::Type{DateTime}, pdt::PreciseDateTime) = DateTime(pdt.datetime, Local)
ZonedDateTime(pdt::PreciseDateTime) = pdt.datetime

trailing_micros(pdt::PreciseDateTime) = pdt.nanos.value / 10^3

dt_and_micros(pdt::PreciseDateTime) = (ZonedDateTime(pdt), trailing_micros(pdt))

function isless(a::PreciseDateTime, b::PreciseDateTime)
    a.datetime < b.datetime || (a.datetime == b.datetime && a.nanos < b.nanos)
end

function ==(a::PreciseDateTime, b::PreciseDateTime)
    (a.datetime == b.datetime) & (a.nanos == b.nanos)
end

function n_trailing_zero(number)
    n_digit = 0
    working_number = number
    while working_number != 0
        working_number, r = divrem(working_number, 10)
        r != 0 && break
        n_digit += 1
    end
    return n_digit
end

function clip_trailing(number)
    n_trail = n_trailing_zero(number)
    div(number, 10 ^ n_trail)
end

const TZ_DATEFMT = DateFormat("zzzz")

function show(io::IO, pdt::PreciseDateTime)
    dt = DateTime(pdt.datetime, Local)
    print(io, dt)
    millis = convert(Millisecond, dt)
    trailing_millis = millis - convert(Millisecond, floor(millis, Second))
    raw_millis = trailing_millis.value
    n_trailing_zero_milli = n_trailing_zero(raw_millis)
    millis_str = raw_millis == 0 ? ".000" : repeat('0', n_trailing_zero_milli)
    raw_nanos = pdt.nanos.value
    nano_str = raw_nanos == 0 ? "" : millis_str * @sprintf("%06d", raw_nanos)
    if isempty(nano_str)
        clipped_nano_str = nano_str
    else
        last_nonzero = findlast(!isequal('0'), nano_str)
        clipped_nano_str = SubString(nano_str, 1, last_nonzero)
    end
    print(io, clipped_nano_str)
    print(io, format(pdt.datetime, TZ_DATEFMT))
end

show(io::IO, ::MIME"text/plain", pdt::PreciseDateTime) =
    print(io, "PreciseDateTime:\n    ", pdt)

function +(pdt::PreciseDateTime, ns::Nanosecond)
    sum_nanos = ns + pdt.nanos
    sum_millis = floor(sum_nanos, Millisecond)
    trailing_nanos = sum_nanos - convert(Nanosecond, sum_millis)
    new_zdt = pdt.datetime + sum_millis
    PreciseDateTime(new_zdt, trailing_nanos)
end

+(pdt::PreciseDateTime, p::TimePeriod) = pdt + convert(Nanosecond, p)

add_nanos(pdt::PreciseDateTime, ns::Real) = pdt + Nanosecond(round(Int, ns))
add_nanos(dt::AbstractDateTime, nanos::Real) = add_nanos(PreciseDateTime(dt), nanos)
add_seconds(dt::AbstractDateTime, sec::Real) = add_nanos(dt, sec * 10^9)

duration(start::PreciseDateTime, stop::PreciseDateTime) = stop - start

function duration(tstart::DateTime, microstart::Real, tend::DateTime, microend::Real)
    micro_diff = Microsecond(tend - tstart).value + (microend - microstart)
    micro_diff / 10^6
end

struct RangeBound
    datetime::PreciseDateTime
    inclusive::Bool
end
function RangeBound(dt::DateTime, micros::Integer = 0, inclusive::Bool = true)
    RangeBound(PreciseDateTime(dt, micros), inclusive)
end

struct TSRange
    lower::RangeBound
    upper::RangeBound
    function TSRange(lower::RangeBound, upper::RangeBound)
        if lower.datetime > upper.datetime
            throw(ArgumentError("Bounds are not well ordered"))
        end
        new(lower, upper)
    end
end

function TSRange(lower::PreciseDateTime, upper::PreciseDateTime)
    TSRange(RangeBound(lower, true), RangeBound(upper, true))
end

function show(io::IO, r::TSRange)
    ioc = IOContext(io, :postgres => true)
    lb = ifelse(r.lower.inclusive, '[', '(')
    rb = ifelse(r.upper.inclusive, ']', ')')
    print(io, lb)
    print(ioc, r.lower.datetime)
    print(io, ',')
    print(ioc, r.upper.datetime)
    print(io, rb)
end

show(io::IO, ::MIME"text/plain", r::TSRange) =
    print(io, "TSRange time stamp range:\n    ", r)

function check_overlap(a::TSRange, b::TSRange)
    check_overlap(a.lower.datetime, a.upper.datetime, b.lower.datetime, b.upper.datetime)
end

duration(a::TSRange) = a.upper.datetime - a.lower.datetime # seconds
