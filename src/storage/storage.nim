#[
 Storage utility
]#
import std/[os, tables], jsony, chronicles

type
 StorageType* = enum
  stCache
  stData
  
 Storage* = ref object of RootObj
  cache: TableRef[string, string]
  data: TableRef[string, string]

proc get*(storage: Storage, name: string, stype: StorageType): string =
 case stype:
  of stCache:
   storage.cache[name]
  of stData:
   storage.data[name]

proc set*(storage: Storage, name, value: string, stype: StorageType) =
 case stype:
  of stCache:
   storage.cache[name] = value
  of stData:
   storage.data[name] = value

proc save*(storage: Storage) =
 let
  serializedCache = jsony.toJson(storage.cache)
  serializedData = jsony.toJson(storage.data)

 if not existsDir(getCacheDir() & "ferus"):
  createDir(getCacheDir() & "/ferus")
 
 writeFile(
  getCacheDir() & "/ferus/" & "FERUS_CACHE", 
  serializedCache
 )

proc newStorage*: Storage =
 Storage(
  cache: newTable[string, string](), 
  data: newTable[string, string]()
 )

proc loadStorage*: Storage =
 let deserializedCache = open(
  getCacheDir() & "/ferus/" & "FERUS_CACHE"
 ).readFile().fromJson[TableRef[string, string]]()
 defer:
  fatal "[src/storage/storage.nim] loadStorage(): failed to open cache file!"
  file.close()
  quit 1

 Storage(
  cache: deserializedCache,
  # TODO(xTrayambak): work on storage
 )