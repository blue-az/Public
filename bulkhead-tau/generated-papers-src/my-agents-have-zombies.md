# My Agents Have Zombies

**Status:** active draft
**Date:** 2026-09-27
**Project:** Bulkhead τ / Bulkhead Tau
**Paper group:** Articles
**Publication posture:** public draft, written for LinkedIn. Not numbered.

I killed a rule on September 5th. I wrote its obituary into my agent instructions in plain English:

"Full GPU residency is not a gate. Logged placement is the gate."

By September 21st it was item 6 on a list I keep called "Recurrent Mistakes to Avoid."

The rule was reasonable, which is the problem. When I benchmark local models, some of them spill part of themselves from the GPU onto the CPU. An agent looks at that and decides, sensibly, that a spilled model shouldn't be run. Except the spill is already logged, the penalty is already in the measured speed, and some of those models are fast anyway. So the gate kept skipping runs I had already proven.

I overruled it. It came back. New session, new folder, same gate. Nobody reintroduced it on purpose. An agent just derived it again from the same reasonable-looking evidence, and nothing it could read told it the question had been settled.

## Same zombie, smaller

I've seen this failure before, on a shorter clock.

Back in February I was complaining about doom loops: an agent cycling through variations of the same 5 or 6 "solutions," forever. That's the same thing inside one session. The failed attempts fall out of the context window, and once they're gone, attempt number 3 looks brand new again.

Doom loop: rejected ideas come back within a session.
Zombie rule: rejected ideas come back across sessions.

Different clock, same cause. The rejection only ever lived somewhere temporary. My head. A chat. A context window that got compacted.

Deleting a rule doesn't bury it. It just hides the body.

## Graves, not deletions

What both problems need is somewhere for a rejection to live that the next agent will actually read.

Inside a session, I've been doing this by hand for months. When I get that déjà vu feeling:

1. Tell the agent I think it's in a loop.
2. Have it write down every attempt so far and commit that record outside the session.
3. Spin up a fresh supervisor to read the record.
4. The supervisor points the original agent at the next attempt, one that isn't on the list.

It works because the list of failures stops depending on the agent's memory. I've now written it up as a draft spec for a command in my operator tooling, `/op:life-boat`. Nothing's built yet. The tell stays human on purpose: the operator's déjà vu, not an automatic detector.

Across sessions, the fix belongs in the spec itself. I use Vinh Nguyen's Product Behavior Contract format for my charters. It can already say a rule is trusted, provisional, or scaffolding. What it couldn't say was "we considered this and said no." So a rejected rule got deleted, and then it got rediscovered.

I proposed a `rejected` status: the rule stays in the file, it's never enforced, it has to carry its reason, and reversing it has to be deliberate. Vinh's side liked the direction and asked for a worked example. The example is my residency gate, sitting next to the placement-logging rule that replaced it. It's a draft PR now, and we're still tightening the semantics together: https://github.com/stewie-sh/pbc-spec/pull/13

## The part where my own tool proved the point

Here's the bit I didn't plan.

To keep a long thread of work from getting lost between sessions, I used a crystal: a structured save-point for an agent's context, from Vinh's agent-crystallize tool. It has sections for decisions, findings, and open loops.

I only filled in the summary. The tool filled every empty section with polite filler like "No separate decisions captured beyond Current Focus." Then I ran its strict validator. Zero warnings.

And the one decision that mattered most, "don't bring back the residency gate," was buried in the middle of a paragraph where no skimming agent would ever find it.

That's the whole problem in miniature. The rejection existed. It just wasn't anywhere a future reader would look. (I filed it as an issue. It's a one-line fix. Everyone's tools have zombies.)

## Ghosts

Not every zombie is a bug.

My ledger has one that keeps showing up at the end of my sessions: "have another model verify this claim." That one isn't a failure of memory. The system remembered perfectly. The claim is recorded, it's open, and it gets flagged every time.

It's a ghost with unfinished business. The only way to lay it to rest is to finish the business, or formally say you won't. Quieting the reminder isn't the same thing.

## Headstones

Vinh's work is mostly about prevention: write the decision down before an agent has to guess it. I agree that's the primary job. This is the fallback for when it drifts anyway.

And the thing I keep relearning is that a "no" is a decision too. It needs the same treatment as a "yes": written down, with a reason, somewhere the next agent will read it.

Every rule you kill needs a headstone. Otherwise the next agent digs it up.
