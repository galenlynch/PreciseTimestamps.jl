const MATLAB_DATE_FORMAT = dateformat"d-u-y H:M:S"
const ISO_8601_FINE_DATE_FORMAT = dateformat"YYYY-mm-ddTHH:MM:SS.sss"

function matlab_datestring(datestr::AbstractString)
    DateTime(datestr, MATLAB_DATE_FORMAT)
end

function iso_fine_datestring(datestr::AbstractString)
    DateTime(datestr, ISO_8601_FINE_DATE_FORMAT)
end

"""
    datevec_to_precisedatetime(datevec::Array{T}) where {T<:Real}

Convert matlab datevec into PreciseDateTime
"""
function datevec_to_precisedatetime(datevec::Array{T}) where {T<:Real}
    add_seconds(
        DateTime(datevec[1], datevec[2], datevec[3], datevec[4], datevec[5], 0, 0),
        datevec[6],
    )
end
