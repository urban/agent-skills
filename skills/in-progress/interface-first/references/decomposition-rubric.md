# Decomposition, behavioral ownership, and placement

Apply three connected decisions: what deserves a boundary, who owns its behavior, and where it belongs. Map the roles below onto the project’s actual package/dependency rules. This rubric does not impose package names, fixed layer counts, or an architecture migration. The [named UI module contract](workflow-contract.md#named-ui-modules-and-review-coverage) requires clear ownership, a small semantic interface and runnable review coverage; the project selects directory, module and colocation requirements.

## Draw useful boundaries

| Question           | Keep together when                                                     | Refine a boundary when                                                                       |
| ------------------ | ---------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| Purpose            | Parts express one recognizable responsibility.                         | A subpart has a distinct purpose the user can name and steer independently.                  |
| Interface          | Splitting exposes private event sequences or substantial coordination. | Small semantic inputs/actions/outputs and supplied dependencies describe the unit clearly.   |
| Change             | Parts normally change together for the same reason.                    | Independent concerns cause unrelated edits or growing conditional behavior.                  |
| State and lifetime | Transitions and state are tightly coordinated within one interaction.  | A concern has a separately meaningful lifetime or owner with a small coordination interface. |
| Review             | A fragment is meaningful mainly as anatomy within its parent.          | Important states can be operated with controlled inputs and checked in surrounding context.  |

Stop splitting when an additional boundary adds names or plumbing without improving understanding, steering, reuse, or meaningful verification. Split an oversized unit when independently steerable concerns can have clearer contracts. Visual size, visual tree depth, line count, Atomic Design labels, and number of uses do not decide the boundary.

Distinguish a **named renderable element** from a **state/variant or flow annotation**, and a **local module interface** from a **package-level public export**. A named renderable internal part needs clear implementation ownership, a semantic interface and runnable review coverage; follow project rules for its own directory and module entry. It can remain nested and private to its owner. Keep implementation and machine protocols behind that interface. A state does not become a component merely to gain coverage; demonstrate it within its element’s review scenarios. Meaningful product interactions can justify encapsulation before a second production consumer exists.

## Identify state, behavior, and effect owners

| Concern                                                                                                    | Responsible role                                                                                                                           |
| ---------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| Product-independent interaction semantics: focus, keyboard behavior, expansion, generic selection.         | Foundational UI may own this behavior and local state/machine where warranted.                                                             |
| Product-specific task interaction: drafts, scope choices, follow/browse intent, pending interaction state. | Product Client composes foundational controls and exposes semantic actions/views/outcomes.                                                 |
| Validity, accepted facts, persistence, operational device work.                                            | Domain/capability owners retain authority and mechanisms. Client requests work and presents truthful outcomes through supplied interfaces. |
| Placement, navigation, provider selection, runtime connection and integration lifetime.                    | Application host composes the interaction into the actual runtime.                                                                         |

One owner per value, decision, and resource. A child can present a parent-controlled value without a competing authoritative copy. An uncommitted Client draft can coexist with externally accepted facts. Keep derivable views derived.

Describe meaningful behavior through states, events, transitions and associated work. Use statecharts for warranted finite lifecycles; simple presentation does not require a machine. Visual and behavioral nesting can differ. Effects, cancellation, disposal and stale-result handling follow their responsible owner and lifetime. Keep private actors/transition protocols behind semantic interfaces.

## Admit a unit to foundational UI

All of the following must hold:

1. **Generic meaning:** its purpose and contract make sense in an unrelated product. A shared visual brand is compatible with this; product identity or workflow policy is not generic meaning.
2. **Generic behavior:** states, actions and interaction rules retain their meaning with unrelated product data. Generic labels, items, slots, values and callbacks can be appropriate. Renaming product props does not make a domain workflow generic.
3. **Independent dependencies:** it needs no product Client, application internals, domain policy, backend connection or selected provider. It can signal generic intent without owning the caller’s external work.
4. **Useful interface:** normal independent use is understandable without a configuration engine, product flags or exposed private event sequences.
5. **Credible independent use:** a useful domain-neutral example demonstrates the same behavior. No arbitrary minimum consumer count is required; speculative generalization needs evidence.

Failure of a UI condition points to Client only when the unit is a product UI responsibility. Domain authority and host integration remain with their own roles.

## Admit a unit to product Client

The unit presents a coherent product task or composes generic pieces into a product-specific experience. Its semantic inputs, actions, projections/outcomes and dependencies form a clear contract. It can operate with host-supplied connections without importing application internals or selecting concrete providers. UI concerns remain separate from domain authority and operational mechanisms.

Product-specific interactions can be reusable within the product and across suitable hosts. Actual navigation, runtime and feature placement remain host-owned even when a complete feature view belongs in Client. A local screen assembly need not become another Client export merely because it fails the foundational UI test.

If generic mechanism and product policy coexist, split them only when both resulting contracts become clearer. Otherwise retain the coherent product unit until evidence supports extraction. When generic reuse is uncertain, retain the product/local owner and record the uncertainty; promote on evidence. Repetition across product screens alone does not establish foundational placement.

## Boundary examples

| Candidate                                                           | Likely role and reason                                                                                                                                                      |
| ------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Stateful select or generic popover                                  | Foundational UI: keyboard, selection, focus and dismissal semantics can survive replacement of the product data.                                                            |
| Product assignment popover                                          | Client: target identity, assignment scope, drafts and pending work express a product task; authoritative acceptance stays supplied.                                         |
| Option row inside that popover                                      | A named renderable row gets clear ownership and runnable review coverage; project policy selects local modules. Public export and generic placement need separate evidence. |
| Pure waveform correlated with product timelines and identity colors | Client may be appropriate despite stateless rendering; the projections have product meaning. A generic drawing primitive is a separate question.                            |
| Assignment validity, durable save, device mechanism                 | Domain/capability, not UI or Client.                                                                                                                                        |
| Desktop navigation and concrete connection                          | Host integration, not a reusable interaction’s private responsibility.                                                                                                      |

Record the boundary, semantic interface, behavioral authority, reuse scope, placement evidence, consumers, and review entry with the project’s [inventory record](workflow-contract.md#inventory-record). These are reasoned decisions, not a weighted score that can average away a dependency or ownership violation. Design principles may be balanced together while concrete architectural boundaries remain enforceable.
