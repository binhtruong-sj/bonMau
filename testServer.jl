using Sockets

server = listen(8080)
p = [0,0,0,0]
i = 0
@async begin
  while true
    al = readline()
    print(al)
  end
end

while true
  global i
  conn = accept(server)
  i = 0
  for j in 1:4
    if p[j] == 0
      i = j
      break
    end
  end
  println("Accepting ",i)
  p[i] = 1

  @async begin
      while true
        global i
        myID = i
        
          line = readline(conn)
        if line != ""
          println(line," ",(i,myID,p))
        else
          p[myID] = 0
          break
        end
      end

  end

end
