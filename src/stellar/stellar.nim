#[
  Stellar object (de)serializer

  This code is licensed under the MIT license
]#
import jsony, chronicles

proc serialize*[T](obj: T): string =
  jsony.toJson(obj.summarize())

proc deserialize*[T](data: string, obj: T) =
  let deserialized = jsony.fromJson(data)
  obj.construct(deserialized)
