module Politics

import Requests: get

using MySQL
using Requests

include("consts.jl")

function get_politicians(zipcode)
    url = "https://www.googleapis.com/civicinfo/v2/representatives"
    query = Dict("address" => zipcode, "key" => ARGS[1])
    res = get(url; query = query)
    data = Requests.json(res)

    positions = Dict()

    for office in data["offices"]
        for index in office["officialIndices"]
            positions[index + 1] = office["name"]
        end
    end

    j = 1

    for politician in data["officials"]
        keys = ["name", "party", "zipcodes"]
        values = [politician["name"], politician["party"], string(zipcode)]

        if haskey(positions, j)
            push!(keys, "position")
            push!(values, positions[j])
        end

        if haskey(politician, "emails")
            push!(keys, "email")
            push!(values, politician["emails"][1])
        end

        if haskey(politician, "phones")
            push!(keys, "phone")
            push!(values, politician["phones"][1])
        end

        if haskey(politician, "urls")
            push!(keys, "website")
            push!(values, politician["urls"][1])
        end

        if haskey(politician, "channels")
            for channel in politician["channels"]
                push!(keys, lowercase(channel["type"]))
                push!(values, channel["id"])
            end
        end

        values_str = ""
        types = []

        for i = 1:length(values)
            values_str = string(values_str, i == length(values) ? "?" : "?, ")
            push!(types, MYSQL_TYPE_STRING)
        end

        command = string("INSERT INTO politicians (", join(keys, ", "), ") VALUES (", values_str, ")")

        mysql_stmt_prepare(conn, command)
        mysql_execute(conn, types, values)

        j += 1
    end
end

conn = mysql_connect("localhost", "root", "cityhub", "cityhub")

k = 0

for zipcode in NYC_ZIPCODES
    get_politicians(zipcode)
    k += 1

    if k > 2
        break
    end
end

mysql_disconnect(conn)

end
