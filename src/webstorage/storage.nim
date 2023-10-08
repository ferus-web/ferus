#[
  Incomplete WHATWG web storage API
]#
import std/[tables, options], jsony

type
  Storage* = ref object of RootObj
    length*: uint64
    db: TableRef[string, string]

proc getItem*(storage: Storage, key: string): string =
  storage.db[key]

proc setItem*(storage: Storage, key, value: string) =
  storage.db[key] = value

proc removeItem*(storage: Storage, key: string) =
  storage.db.del(key)

proc build*(data: string): Storage =
  data.fromJson(Storage)

proc serialize*(storage: Storage): string =
  toJson(storage)
