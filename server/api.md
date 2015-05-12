连接服务器:
gate.gateHandler.getConnector
connector.entryHandler.login
player.playerHandler.update

开始游戏:
waitToStart: area.join, area.ready, *area.start, area.quit
choosingLord: *area.lordChoosed, area.chooseLord, *area.start, *area.quit
playing: area.play, *area.gameOver, *area.quit

waitToStart: area.areaHandler.join, **area.areaHandler.ready, area.areaHandler.quit
choosingLord: **area.areaHandler.chooseLord, *area.quit
playing: **area.areaHandler.play, *area.quit

area.areaHandler.connect/disconnect

area.areaHandler.join -> [area.join]
area.areaHandler.ready -> [area.ready, area.start]
area.areaHandler.chooseLord -> [area.lordChoosed, area.chooseLord, area.start]
area.areaHandler.play -> [area.win]

area.areaHandler.quit -> [area.quit]
create or join area -> loading -> show player who joined in
发牌:
choose landlord -> add left 3 cards to landlord
出牌:
出牌超时 -> 机器人自动出牌
掉线:
机器人自动出牌
判断胜负:
继续或者退出:


TODO:
1. robot with AI




