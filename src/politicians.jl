# Retrieves politicians from Google and inserts/updates them accordingly

function get_politicians(api_key, conn, zipcode)
    url = "https://www.googleapis.com/civicinfo/v2/representatives"
    query = Dict("address" => zipcode, "key" => api_key)
    response = get(url; query = query)
    response_data = Requests.json(response)

    positions = Dict()

    for office in response_data["offices"]
        for index in office["officialIndices"]
            positions[index + 1] = office["name"]
        end
    end

    for (i, politician) in enumerate(response_data["officials"])
        data = Dict("name" => politician["name"], "party" => politician["party"], "zipcodes" => string(zipcode))

        if haskey(positions, i)
            data["position"] = positions[i]
        end

        if haskey(politician, "photoUrl")
            data["photo_url"] = politician["photoUrl"]
        end

        if haskey(politician, "emails")
            data["email"] = politician["emails"][1]
        end

        if haskey(politician, "phones")
            data["phone"] = politician["phones"][1]
        end

        if haskey(politician, "urls")
            data["website"] = politician["urls"][1]
        end

        if haskey(politician, "channels")
            for channel in politician["channels"]
                data[lowercase(channel["type"])] = channel["id"]
            end
        end

        mysql_stmt_prepare(conn, "SELECT * FROM politicians WHERE name=?")
        mysql_execute(conn, [MYSQL_TYPE_STRING], [politician["name"]])

        existing_data = 0

        for row in MySQLRowIterator(conn, [MYSQL_TYPE_STRING], [politician["name"]])
            existing_data = row # there should only ever be one
        end

        if existing_data == 0
            values_str = ""
            keys = []
            types = []
            values = []

            for (j, (key, val)) in enumerate(data)
                values_str = string(values_str, j == length(data) ? "?" : "?, ")
                push!(keys, key)
                push!(types, MYSQL_TYPE_STRING)
                push!(values, val)
            end

            command = string("INSERT INTO politicians (", join(keys, ", "), ") VALUES (", values_str, ")")

            mysql_stmt_prepare(conn, command)
            mysql_execute(conn, types, values)
        else
            new_data = Dict()

            zipcodes = map(y -> parse(Int64, y), split(existing_data[3], ","))

            if !in(zipcode, zipcodes)
                push!(zipcodes, zipcode)
                new_data["zipcodes"] = join(zipcodes, ",")
            end

            check(pos, key) = begin
                if haskey(data, key)
                    if isnull(existing_data[pos])
                        new_data[key] = data[key]
                    elseif data[key] != get(existing_data[pos])
                        new_data[key] = data[key]
                    end
                end
            end

            check(4, "position")
            check(5, "party")
            check(6, "photo_url")
            check(7, "email")
            check(8, "phone")
            check(9, "website")
            check(10, "facebook")
            check(11, "googleplus")
            check(12, "twitter")
            check(13, "youtube")

            if length(new_data) > 0
                keys_values_str = ""
                types = []
                values = []

                for (j, (key, val)) in enumerate(new_data)
                    keys_values_str = string(keys_values_str, key, "=?", j == length(new_data) ? "" : ",")
                    push!(types, MYSQL_TYPE_STRING)
                    push!(values, val)
                end

                command = string("UPDATE politicians SET ", keys_values_str, " WHERE id=", existing_data[1])

                mysql_stmt_prepare(conn, command)
                mysql_execute(conn, types, values)
            end
        end
    end
end
