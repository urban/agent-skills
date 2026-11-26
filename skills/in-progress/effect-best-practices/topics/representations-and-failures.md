# Representations and failures

Choose domain and boundary representations from the obligations they serve. Put accepted legacy spellings and normalization at the boundary; do not spread provider or storage vocabulary through domain behavior. Keep authorization and existence decisions with application capabilities rather than hiding them in a codec.

Define absence by intent. An omitted patch field may preserve a value while an explicit clear removes it. Do not let a convenient optional field or default erase that distinction or fabricate a domain fact. Similarly, decide whether an update targeting no value is a valid no-op or an actionable failure before selecting an optic or transition implementation.

State compatibility direction: accepting older input and emitting output that older consumers understand are separate promises. A read-modify-write boundary must decide whether unfamiliar data must survive. Choose identity, canonicalization, or losslessness as the intended representation law rather than assuming every codec promises all three.

Design expected errors around caller decisions. Keep construction failures with the owner able to choose startup recovery; keep operation failures in the contract of the already-built capability. Public variants and messages should be stable and safe; sensitive or unbounded external evidence belongs in controlled diagnostics.

**Tradeoff:** collapsing representations and errors simplifies signatures only when it preserves meaning. Retain distinctions that change application behavior; leave exact Schema, Cause, and Optic mechanics to Effect's current documentation and source.
