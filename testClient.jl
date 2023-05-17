using GameZero
using Sockets
checkServer = false

function clientSetup(serverURL,port)
    try
        ac = connect(serverURL,port)
        println((serverURL,port))
        return ac
    catch
        return 0
    end
end

port = 8080
myIP = ip"127.0.0.1"

nw = clientSetup(myIP,port)
while true
    aline = readline()
    println(nw,aline)
end