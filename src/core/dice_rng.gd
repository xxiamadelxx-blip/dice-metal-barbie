extends RefCounted
## Unbiased range reduction of secure bytes. Never substitute the physics sandbox randf for dice results.
## Optional source is test-only injection. Production calls Crypto.generate_random_bytes().

static func pick(sides: int, source: Callable = Callable()) -> int:
    if sides < 2 or sides > 1000000:
        push_error("Invalid number of sides")
        return -1
    var width := 1
    var total := 256
    while total < sides:
        width += 1
        total *= 256
    var limit := total - total % sides
    var crypto := Crypto.new()
    for attempt in range(10000):
        var chunk: PackedByteArray = source.call(width) if source.is_valid() else crypto.generate_random_bytes(width)
        if chunk.size() != width:
            push_error("Invalid entropy source response")
            return -1
        var value := 0
        for byte in chunk:
            value = value * 256 + byte
        if value < limit:
            return 1 + value % sides
    push_error("Entropy rejection budget exceeded")
    return -1

