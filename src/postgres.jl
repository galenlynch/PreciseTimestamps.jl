const POSTGRES_DATE_FORMAT = dateformat"YYYY-mm-dd HH:MM:SSz"
const POSTGRES_DATE_FORMAT_NO_TZ = dateformat"YYYY-mm-dd HH:MM:SS.s"
const PSQL_DATETIME_REG =
    r"(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\.?(\d{0,3})(\d{0,3})([-+]\d{2}(?::\d{2})?)?"
const PSQL_RANGE_REG = r"([\[\(])\"([^\"]*)\",\s*\"([^\"]*)\"([\)\]])"
const POSTGRES_ARRAY_REG = r"\{([^\}]*)\}"

postgres_time_str(pdt::PreciseDateTime) = repr(pdt)

function postgres_time_str(dt::ZonedDateTime, micros::Integer = 0)
    postgres_time_str(add_seconds(dt, micros * 10^-6))
end

function postgres_time_str(dt::DateTime, micros::Integer = 0, zone = localzone())
    postgres_time_str(ZonedDateTime(dt, zone), micros)
end

function PreciseDateTime(datestring::AbstractString)
    m = match(PSQL_DATETIME_REG, datestring)
    isnothing(m) && throw(ArgumentError("Could not parse $datestring"))
    millis_match = something(m[2], "")
    micros_match = something(m[3], "")
    if isnothing(m[4])
        millis_str = '.' * millis_match
        dt = DateTime(m[1] * millis_str, POSTGRES_DATE_FORMAT_NO_TZ)
    else
        zdt = ZonedDateTime(m[1] * m[4], POSTGRES_DATE_FORMAT)
        millis_val = isempty(millis_match) ? 0 : parse(Int, rpad(millis_match, 3, '0'))
        dt = zdt + Millisecond(millis_val)
    end
    nanos = isempty(micros_match) ? 0 : parse(Int, rpad(micros_match, 3, '0')) * 1000
    PreciseDateTime(dt, nanos)
end

function postgres_make_tsrange_str(
    start_dt::ZonedDateTime,
    start_micros::Integer,
    stop_dt::ZonedDateTime,
    stop_micros::Integer;
    start_bracket::Char = '[',
    stop_bracket::Char = ')',
)
    string(
        start_bracket,
        '"',
        postgres_time_str(start_dt, start_micros),
        '"',
        ',',
        '"',
        postgres_time_str(stop_dt, stop_micros),
        '"',
        stop_bracket,
    )
end

function postgres_make_tsrange_str(tsr::TSRange)
    start_dt, start_micros = dt_and_micros(tsr.lower.datetime)
    stop_dt, stop_micros = dt_and_micros(tsr.upper.datetime)
    postgres_make_tsrange_str(
        start_dt,
        round(Int, start_micros),
        stop_dt,
        round(Int, stop_micros);
        start_bracket = ifelse(tsr.lower.inclusive, '[', '('),
        stop_bracket = ifelse(tsr.upper.inclusive, ']', ')'),
    )
end

function TSRange(rangestr::AbstractString)
    m = match(PSQL_RANGE_REG, rangestr)
    isnothing(m) && error("Could not parse ", s, " as TSRange")
    if m[1] == "["
        start_inclusive = true
    elseif m[1] == "("
        start_inclusive = false
    else
        error("Could not parse start bound")
    end
    start_t = PreciseDateTime(m[2])
    stop_t = PreciseDateTime(m[3])
    if m[4] == "]"
        stop_inclusive = true
    elseif m[4] == ")"
        stop_inclusive = false
    else
        error("Could not parse stop bound")
    end
    TSRange(RangeBound(start_t, start_inclusive), RangeBound(stop_t, stop_inclusive))
end

function postgres_tsrange_to_datetime_micros(timerange_str::AbstractString)
    tr = TSRange(timerange_str)
    (dt_and_micros(tr.lower.datetime)..., dt_and_micros(tr.upper.datetime)...)
end

function parse_postgres_array(s::AbstractString)
    m = match(POSTGRES_ARRAY_REG, s)
    isnothing(m) && return nothing
    content = m[1]
    strip.(split(content, ',', keepempty = false))
end

postgres_tuple_list(itr) = '(' * join(imap(string, itr), ',') * ')'
postgres_tuple_rows(itr) = join(imap(postgres_tuple_list, itr), ", ")
