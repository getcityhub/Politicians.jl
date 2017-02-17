module Politics

using MySQL
using Requests

include("consts.jl")
include("politicians.jl")

api_key = ARGS[1]
conn = mysql_connect("localhost", "root", "cityhub", "cityhub")

for zipcode in NYC_ZIPCODES
    println("Retrieving politicians from ", zipcode, "...")
    get_politicians(api_key, conn, zipcode)
end

mysql_disconnect(conn)

end
