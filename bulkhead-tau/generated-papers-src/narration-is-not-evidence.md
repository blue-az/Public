# Narration Is Not Evidence. Not Even Mine.

**Status:** active draft
**Date:** 2026-10-01
**Project:** Bulkhead τ / Bulkhead Tau
**Paper group:** Articles
**Publication posture:** public draft, written for LinkedIn. Not numbered.

I built a system whose whole job is to not take an agent's word for it.

Then an AI interviewed me about it for 25 minutes, and I was the one making claims without evidence.

## The setup

It was a screening interview for contract coding work, run by an AI interviewer. No coding, no whiteboard. Just "walk me through a project you're proud of." Easy, I thought. I picked Operator Control Plane, the ledger I've been building since June.

The pitch is short. Your coding agent says "done, tests pass." Do you actually know that's true? OCP makes that claim checkable. A claim needs evidence attached, and a verification only counts as independent if it comes from a different OS user than the one that made the claim.

I gave that part fine. Then the follow-ups started.

## Question one

"What would happen to users if the ledger recorded or verified a claim incorrectly?"

My answer, more or less verbatim: "That would be on the user." Followed by "it's hard to know exactly what you're asking."

It was not hard to know what it was asking. It was asking the most important question you can ask about a verification system, and I shrugged at it.

## Question two

"How did you verify that UID mode produced a complete record?"

My answer: "It's continuously verified. It's designed by principle that way."

Read that again. Somebody asked a claim-evidence system's author for evidence, and the author gave a claim.

That's the exact sentence my ledger exists to reject. An agent saying "it's tested, trust me" is narration. I was narrating.

## What I should have said

The annoying part is the answers exist. They're in the repo. I just didn't have them loaded.

What happens if a verification is wrong? Three things.

1. The ledger labels how much to trust each verification. If the same OS user who made a claim also verifies it, it's recorded as advisory: the builder vouching for their own work. Only a separate verifier account gets recorded as independent. The system doesn't pretend a self-check was a second opinion.
2. A wrong verification is traceable. Every write records which OS user made it, and every event is hash-chained to the one before it. You can find a bad verification, see who made it, and supersede it. It doesn't get quietly overwritten.
3. And the honest limit: the ledger can't tell whether the verifier was right. If a different identity looks at bad evidence and approves it, the ledger records that faithfully. It enforces who checked and what they attached. Not whether their judgment was any good.

That third one is the real answer, and it's not a weakness I should have been embarrassed about. It's the boundary. I learned it doing V&V under ISO 13485: a signature on a design review doesn't make the design correct. It makes the review accountable. Same thing here.

How do you know the record is complete? The `doctor` command walks the event history and fails on any version gap, any broken hash link, any record that doesn't match its history. Evidence carries a sha256 fingerprint. There are 600+ tests behind it. And again the honest limit: the chain proves nothing was changed or dropped after it was written. It can't prove an agent wrote down everything it did. Which is why claims need attached evidence instead of being taken from the agent's summary.

Thirty seconds each. I had neither.

## The part I got right

One answer did land, and it's worth saying why.

They asked about the hardest decision. I told them the truth: I started by identifying reviewers by harness name. Claude reviewed this, Codex reviewed that. It was intuitive and easy to explain. Audits kept flagging it, and an outside user pointed out a hole. One OS user can type any reviewer name. A different harness name buys nothing.

So in July I switched to OS user IDs. It costs real friction. True enforced mode means a second account and copy-pasting between two windows. I kept an advisory mode for daily use, and it labels itself as advisory.

That answer worked because it had a decision, a reason, a cost, and a date. The other answers had a feeling.

## The part I forgot entirely

They asked for a specific doom loop where the ledger changed what I did next. I'd used it for exactly that two days earlier.

I couldn't remember it. I told a different story, realized halfway through it didn't fit, and said so out loud.

Which is, if you think about it, the best possible argument for the thing I was describing. Memory is a terrible place to keep evidence. Mine included.

## So

I spend a lot of time telling people not to trust an agent that says "done, it works." Turns out the rule doesn't care who's narrating.

If you build verification tooling, try this: have something ask you "what happens when it's wrong?" and "how do you know it's complete?" and answer without opening a file. If you can't, you don't have an answer yet. You have a repo.

Narration is not evidence. Not even mine.
