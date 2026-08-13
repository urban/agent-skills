# Traversals, isos, and tests

A traversal can expose many focuses. Distinguish transforming the collection of focuses from transforming each focused element. Use the element-wise operation for ordinary bulk updates.

Plain path optics clone ordinary arrays/objects. For schema classes, newtypes, maps, sets, URLs, headers, and other custom representations, enter through a schema/newtype/custom iso. A custom iso must round-trip without loss.

Test:

- present and absent focus
- wrong tagged variant/refinement failure
- optional key deletion versus explicit undefined
- traversal element updates and empty traversal
- iso get/set or modify round trip
- service mapping from optic failure text to a stable domain error

Do not use no-op reference identity as the contract; assert value and relevant structural sharing only when guaranteed and meaningful.
