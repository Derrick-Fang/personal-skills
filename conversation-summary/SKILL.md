---
name: conversation-summary
description: Summarize a multi-turn conversation in four parts — a Problem Tree (how the user's questions decomposed the problem), a Knowledge Tree (the final conceptual map), a Knowledge Explanation that follows the Knowledge Tree section by section, and 3–8 Takeaways capturing the new knowledge, corrected understanding, and transferable insights. Use when the user asks to summarize / recap / 复盘 / 总结 a long discussion, asks for a 问题树 / 知识树 / problem tree / knowledge tree / mind map of the conversation, asks what they learned or the key takeaways (要点 / 收获), or wants a structured overview of what was explored and learned.
---

# Conversation Summary

Reconstruct a multi-turn conversation into four parts. Organize by logic and concept, never primarily by conversation order.

- **Problem Tree = how the problem was explored.**
- **Knowledge Tree = how the knowledge is organized.**
- **Knowledge Explanation = the mental model, explained following that structure.**
- **Takeaways = the most important new understanding and insight.**

The two trees are **navigation maps**, not explanations; they may, and usually should, have different shapes. Details live in the Knowledge Explanation.

## Output layout

```text
# Problem Tree
<tree>

# Knowledge Tree
<tree>

# Knowledge Explanation
## <Knowledge Tree branch A>
## <Knowledge Tree branch B>
...

# Takeaways
- ...
```

Draw trees with `├──`, `└──`, `│` in a ```text block. Match the conversation's language.

## 1. Problem Tree

Shows the root problem, major subproblems, how questions drilled down, and which branches remain open.

1. **Root** — the highest-level problem behind the conversation. It may be broader than the first explicit question, but must be supported by the conversation.
2. **Parent → child** — a child is a deeper investigation of its parent.
3. **Merge repeats** — semantically equivalent questions become one canonical node; never one node per turn.
4. **Logical, not chronological** — order by drill-down (System → Component → Mechanism → Problem), not by when it was asked. Avoid flat lists.
5. **Cross-branch questions** — put under a shared interaction node or the most useful parent.
6. **Misconceptions** — an assumption later corrected stays here as a question to resolve, not as a fact.
7. **Open branches** — mark important unresolved ones with `[Open]`.
8. **Compact** — 2–6 major branches, limited depth, short node names, no answers inside the tree.

```text
Root Problem
├── Subproblem A
│   ├── Question A1
│   └── Question A2
└── Subproblem B [Open]
```

## 2. Knowledge Tree

The final high-level mental map — a compact table of contents for the Knowledge Explanation.

1. **Reorganize independently** — do not just turn Problem Tree questions into statements; restructure by concept.
2. **Major concepts only** — concepts, components, mechanisms, categories.
   Exclude: explanations, conclusions, parameter values, causal chains, implementation details, experimental results.
3. **Edges mean containment when containment exists.** If the subject is a system whose parts contain, own, or spawn each other (process → object → field, engine → subsystem → module), the tree's parent → child edges must reproduce that real hierarchy: the outermost thing is the root or a top-level node, and each part sits under the part that holds it. Never flatten such parts into sibling nodes under category labels ("Architecture", "Objects", "Data"), and never split one containment chain across several category branches — that hides exactly the structure the reader needs.
4. **Hang mechanisms on their owner.** A mechanism, data structure, or state that lives inside a component goes under that component (e.g. a scheduling loop under the scheduler that runs it), not under a separate topical branch.
5. **Categories only for the rest.** Use grouping nodes ("Data flow", "Memory model") only for concepts that have no structural owner, or that cut across several components; place them after the containment spine.
6. **Mark non-obvious edges.** When an edge is not plain containment, or multiplicity matters, add a short tag to the child: `[×N per GPU]`, `[shared ref]`, `[spawns]`, `[optional]`. A concept owned by one node and referenced by another appears once under its owner; the other node gets a `[ref → Owner]` leaf, not a duplicate subtree.
7. **Merge related concepts** under a shared parent.
8. **Corrected mental model** — use the understanding reached by the end; drop outdated assumptions.
9. **Compact** — roughly 2–4 levels; a containment chain may go one or two levels deeper when the real nesting requires it.

Bad (categories flatten the hierarchy — Engine and Scheduler look like peers):

```text
Runtime
├── Processes
│   ├── Engine
│   └── Scheduler
└── Objects
    ├── ModelRunner
    └── KV pool
```

Good (edges follow what contains what; cross-cutting concepts come after the spine):

```text
Engine
├── TokenizerManager
├── Scheduler [×N per GPU]
│   ├── Request queue
│   ├── Prefix cache
│   └── ModelRunner
│       ├── Model
│       └── KV pool [shared ref → Scheduler]
└── Detokenizer
Data flow (cross-cutting)
├── Request object
└── Batch object
```

## 3. Knowledge Explanation

The Knowledge Tree is the table of contents of this section: one heading per important branch, in the same order as the tree (nested branches may become sub-headings).

1. **Explain the mental model** — for each concept: what it is, why it exists, how it works, how it relates to nearby concepts. Do not merely restate definitions.
2. **Preserve logical relationships** — make explicit, where useful: component → responsibility, stage → next stage, cause → effect, problem → mechanism, mechanism → tradeoff.
3. **Keep details that change understanding** — important conditions, constraints, equations, configurations, quantitative results, implementation details (file / function names when the discussion was about code). Drop details that do not improve the mental model.
4. **Integrate corrections** — explain the corrected model directly; mention the earlier misconception only when the contrast itself teaches something.
5. **Explain each concept once** — under its most appropriate node; elsewhere, cross-reference that section instead of repeating it.

## 4. Takeaways

The highest-value compression of the whole discussion: what the user should still remember after forgetting the rest. Usually **3–8 items**. Ask: *if the user remembers only a few things from this conversation, what should they be?*

1. **New knowledge** — concepts or mechanisms newly learned that materially expand the user's mental model.
2. **Updated understanding** — an existing concept that gained a deeper or more precise reading: a corrected oversimplification, a hidden dependency, why a known behavior occurs, a link between previously separate concepts.
3. **Insight, not topic names** — each item states an actual understanding.
   - Bad: `- Scheduling` / `- Memory`
   - Good: `- Scheduling performance depends not only on compute cost but on how different workloads interfere with each other.`
4. **Prefer generalizable principles** — e.g. "More parallelism helps only while the computation it saves outweighs the communication and coordination it adds" over "Config X was slower than config Y". Keep a specific fact only when the fact itself matters.
5. **Include important corrections** — an overturned assumption is usually a strong takeaway. When the contrast helps:
   ```text
   Previous model: A ≈ B
   Updated understanding: A and B solve different problems and only look alike at one layer of abstraction.
   ```
6. **Do not re-summarize** each section.

## Self-check before output

- Does any tree node contain an answer, number, or "because"? → move it to the Knowledge Explanation.
- Is the Knowledge Tree just the Problem Tree reworded? → reorganize by concept.
- Does something that contains another thing appear as its sibling, or under a different category branch? → re-nest it so the edge shows containment.
- Is a mechanism filed under a topical branch although one component owns it? → move it under that component.
- Any corrected misconception appearing as knowledge in the Knowledge Tree or Explanation? → state the corrected model instead.
- Duplicate nodes for the same question, or a concept explained twice? → merge / cross-reference.
- Do the Explanation's headings match the Knowledge Tree's branches, in order?
- Is every Takeaway a sentence of insight (not a topic label), and are there no more than ~8?
