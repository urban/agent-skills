# Streams

Define what one subscription means: independent acquisition, a snapshot followed by updates, or deliberate shared fan-out. Keep producer handles private unless the caller truly owns their lifecycle. Prefer a domain stream over making every caller manage a queue or socket.

Choose buffering from the domain's loss and latency budget. A nonblocking producer needs a meaningful pause, rejection, or loss policy; moving waiting work elsewhere does not establish bounded demand. Decide whether ordering applies to observed results, side effects, or both before selecting concurrency.

Choose the recovery unit by what can continue. A rejected record may be skippable under an explicit data-quality policy; an invalid subscription may require termination. A reconnect must define duplication, resume position, and any gap in delivery. Do not claim resumption merely because a source can be restarted.

Keep framing limits and malformed-input policy with the protocol owner. Expose record-level rejection as data only when the consumer needs it; otherwise preserve the operation's failure contract. Long-lived consumption needs a completion or cancellation owner and a shutdown policy for its producer.

**Tradeoff:** sharing a source saves acquisition but couples subscribers' lifetimes and delivery behavior. Independent subscriptions cost more but can preserve isolation. Choose from the product's delivery contract; use Effect's source and decoder documentation for implementation details.
