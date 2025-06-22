$wallet = "BTC:1H8fueovMvcQLArhxw7P4QZ3FAfhEZg7CB.worker1"
$pool = "159.203.162.18:3333"
$cpuThreads = 1
$gpuPriority = 2
$xmrigArgs = "--algo randomx --url $pool --user $wallet --pass x --cpu-threads $cpuThreads --cuda-priority $gpuPriority --donate-level 1 --print-time 60 --log-file miner.log --no-color --api-port 0"
$xmrigArgs
