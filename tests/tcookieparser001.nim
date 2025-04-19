import std/unittest
import components/web/cookie/parsed_cookie
import pkg/shakar

suite "basic cookie parsing":
  let ck = parseCookie(
    "password=supersafepassword; Expires=Wed, 09 Jun 2024 10:18:14 GMT; Path=/; Domain=example.com; Secure; HttpOnly; SameSite=Strict"
  )
  assert *ck, "Cookie couldn't be parsed"

  let cookie = &ck

  test "can parse domain":
    assert &cookie.domain == "example.com"

  test "can parse name":
    assert cookie.name == "password"

  test "can parse value":
    assert cookie.value == "supersafepassword"

  test "can parse same site attribute":
    assert cookie.sameSiteAttribute == ssStrict

  test "can parse secure attribute":
    assert cookie.secureAttributePresent == true

  test "can parse http only attribute":
    assert cookie.httpOnlyAttributePresent == true

  test "can parse expiry time from Expires attribute":
    assert *cookie.expiryTimeFromExpiresAttribute, "Failed to parse expiry date"
