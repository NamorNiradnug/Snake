import os, options, times, strformat, strutils

import snake
import illwill
import argparse

var parser = newParser:
  help("Simple TUI-based snake game writen in Nim")
  arg("speed", default=some("10"), help="Snake speed (steps per second)")

let args = parser.parse()
let step_rate =
  try:
    1 / parseInt(args.speed).float
  except:
    0.1


proc onExit() {.noconv.} =
  illwillDeinit()
  quit(0)

proc drawBoard(tb: var TerminalBuffer, board: Board, start: tuple[x, y: int]) =
  for x in 0..board.width - 1:
    for y in 0..board.height - 1:
      let (ch, color) =
        case board[x][y].kind
        of TileKind.Snake:
          if board[x][y].next.isNone:
            ("@", fgRed)
          else:
            ("#", fgRed)
        of TileKind.Empty:
          (" ", fgNone)
        of TileKind.Wall:
          ("\u2588", fgWhite)
        of TileKind.Food:
          ("$", fgGreen)
      tb.write(start.x + x, start.y + y, color, ch)


var current_centred_msg = ""
proc setCentredMessage(tb: var TerminalBuffer, msg: string) =
  if msg == current_centred_msg:
    return
  tb.write((tb.width - current_centred_msg.len) div 2, tb.height - 2, ' '.repeat(current_centred_msg.len))
  tb.write((tb.width - msg.len) div 2, tb.height - 2, msg)
  current_centred_msg = msg

illwillInit()
setControlCHook(onExit)
hideCursor()
var tb = newTerminalBuffer(terminalWidth(), terminalHeight())

block:
  var borders = newBoxBuffer(tb.width, tb.height)
  borders.drawRect(0, 0, borders.width - 1, borders.height - 3)
  borders.drawRect(0, borders.height - 3, borders.width - 1, borders.height - 1)
  tb.write(borders)

var game = initGame(tb.width - 2, tb.height - 4)
var last_step_time = epochTime()
var paused = true
while true:
  let key = getKey()
  if not paused:
    let new_dir =  
      case key
      of Key.Up:    Direction.Up
      of Key.Down:  Direction.Down
      of Key.Left:  Direction.Left
      of Key.Right: Direction.Right
      else: game.snake.direction
    game.turn(new_dir)
  case key
  of Key.Space: paused = not paused
  of Key.Q: onExit()
  else: discard
  if epochTime() - last_step_time >= step_rate and not paused:
    game.step()
    last_step_time = epochTime()
  tb.drawBoard(game.board, (x: 1, y: 1))
  tb.write(1, tb.height - 2, &"Score: {game.score}")
  if game.state == Running and paused: tb.setCentredMessage("Paused")
  elif game.state == Lose: tb.setCentredMessage("Game over! (press Q to exit)")
  else: tb.setCentredMessage("")
  tb.display()
  sleep(20)

