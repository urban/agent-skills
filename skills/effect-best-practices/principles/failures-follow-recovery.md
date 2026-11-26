# Let failures follow recovery decisions

**Apply when:** designing a service error vocabulary, adapting a provider, or selecting terminal handling.

Expose a failure distinction when it changes a caller's recovery, rendering, retry, or remediation. Translate where both external meaning and domain intent are known. Keep operator diagnostics separate from the stable public contract.

**Example:** conflict and unavailability may require different user actions; several vendor status codes may all mean the same unavailable capability. Preserve diagnostic evidence without publishing the vendor taxonomy.

**Tradeoff:** fewer variants can erase an actionable difference, while a detailed union can make every caller understand infrastructure. A caller's inability to recover does not by itself turn an operational failure into a defect; choose terminal handling at the owner with that authority.
