module Politics

using MySQL
using ProgressMeter
using Requests

include("consts.jl")
include("politicians.jl")

if length(ARGS) > 0
  api_key = ARGS[1]
  conn = mysql_connect("localhost", "root", "cityhub", "cityhub")

  progress = Progress(length(NYC_ZIPCODES), 1, "Retrieving politicians...", 32)

  for zipcode in NYC_ZIPCODES
      get_politicians(api_key, conn, zipcode)
      next!(progress)
  end

  mysql_disconnect(conn)
else
  println("A key for the Google Civic Information API must be passed as an argument in order to retrieve politician data.")
end

end
