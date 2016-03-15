# runs benchmark for 20 seconds, using 4 threads, and keeping 30 HTTP connections open

:os.cmd('wrk -t4 -c30 -d20s --timeout 2000 "http://127.0.0.1:3737/play?name=julio&random=2"') |> IO.puts
