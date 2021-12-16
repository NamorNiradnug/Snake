import std/[options, sequtils, random, macros]


type Position* = tuple[x, y: int]

type
  TileKind* {.pure.} = enum
    Empty, Wall, Food, Snake

  Tile* = object
    case kind: TileKind
    of Snake:
      next, prev: Option[Position]
    else:
      discard

type Board* = seq[seq[Tile]]

type Direction* = enum
  Up = 0, Left = 1, Down = 2, Right = 3

const toXY* = [
  Up:    (x: 0, y: -1),
  Left:  (x: -1, y: 0),
  Down:  (x: 0, y: 1),
  Right: (x: 1, y: 0)
]

type Snake = object
  head, tail: Position
  direction: Direction

type
  GameState* = enum
    Running, Lose  # i like this game because you can't win

  Game* = object
    board: Board
    state: GameState
    snake: Snake
    score: int
template exportGetter(`type`: untyped, property: untyped): untyped =
  proc `property`*(self: `type`): auto = self.property

Tile.exportGetter(kind)
Tile.exportGetter(next)
Tile.exportGetter(prev)
Game.exportGetter(snake)
Game.exportGetter(score)
Game.exportGetter(state)
Game.exportGetter(board)
Snake.exportGetter(direction)

proc width*(board: Board): int = board.len
proc height*(board: Board): int = board[0].len
proc posOnBoard*(board: Board, pos: Position): bool = 0 <= pos.x and pos.x < board.width and 0 <= pos.y and pos.y < board.height

template `[]`*(board: Board, pos: Position): untyped = board[pos.x][pos.y]
proc `[]=`(board: var Board, pos: Position, val: Tile) = board[pos.x][pos.y] = val

const INITIAL_SNAKE_PARAMS = (length: 5, direction: Up)

proc spawnFood(game: var Game) =
  game.board[toSeq(0..game.board.width * game.board.height - 1).mapIt((x: it mod game.board.width, y: it div game.board.width)).filterIt(game.board[it.x][it.y].kind == TileKind.Empty).sample()] = Tile(kind: Food)

proc initGame*(width: range[3..high(int)], height: range[2 * INITIAL_SNAKE_PARAMS.length + 2..high(int)]): Game =
  result.board = repeat(repeat(Tile(kind: Empty), height), width)
  const LENGTH = INITIAL_SNAKE_PARAMS.length
  let head = (x: width div 2, y: height div 2)
  result.snake.head = head
  result.snake.tail = (x: head.x, y: head.y + LENGTH - 1)
  result.snake.direction = INITIAL_SNAKE_PARAMS.direction
  for dy in 0..LENGTH - 1:
    let next =
      if dy != 0: some((head.x, head.y + dy - 1))
      else: none(Position)
    let prev =
      if dy != LENGTH - 1: some((head.x, head.y + dy + 1))
      else: none(Position)
    result.board[head.x][head.y + dy] = Tile(kind: TileKind.Snake, prev: prev, next: next)
  for x in 0..width - 1:
    result.board[x][0] = Tile(kind: TileKind.Wall)
    result.board[x][^1] = Tile(kind: TileKind.Wall)
  for y in 0..height - 1:
    result.board[0][y] = Tile(kind: TileKind.Wall)
    result.board[^1][y] = Tile(kind: TileKind.Wall)
  result.spawnFood()
  result.score = 0
  result.state = Running


proc moveHead(game: var Game, new_pos: Position) = 
  game.board[new_pos] = Tile(kind: TileKind.Snake, next: none(Position), prev: some(game.snake.head))
  game.board[game.snake.head].next = some(new_pos)
  game.snake.head = new_pos

proc step*(game: var Game) =
  if game.state != Running:
    return
  let delta = toXY[game.snake.direction]
  let next_pos: Position = (game.snake.head.x + delta.x, game.snake.head.y + delta.y)
  if not game.board.posOnBoard(next_pos):
    game.state = Lose
    return
  case game.board[next_pos].kind
  of TileKind.Snake, TileKind.Wall:
    game.state = Lose
  of TileKind.Empty:
    game.moveHead(next_pos)
    game.snake.tail = game.board[game.snake.tail].next.get
    game.board[game.board[game.snake.tail].prev.get] = Tile(kind: TileKind.Empty)
    game.board[game.snake.tail].prev = none(Position)
  of TileKind.Food:
    game.score += 1
    game.moveHead(next_pos)
    game.spawnFood()

proc turn*(game: var Game, dir: Direction) =
  if dir.int mod 2 != game.snake.direction.int mod 2:
    game.snake.direction = dir

