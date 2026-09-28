# The Substrate Is the Decisions

**Status:** active draft
**Date:** 2026-09-27
**Project:** Bulkhead τ / Bulkhead Tau
**Paper group:** Articles
**Publication posture:** public draft, written for LinkedIn. Not numbered.

I asked three local models 247 questions about pacemaker and defibrillator implants. One of them made up an answer 47% of the time.

Not a vague answer. Confident ones. "0 registered US implants" for a device family with 53,000 of them.

The other two mostly said "I don't know," which honestly is the correct answer when you don't know. They were right 5 to 11% of the time, and almost all of that was guessing which company led a category.

Then I asked the same 247 questions again, but this time each model got the answer from my database first and only had to say it back.

Right 100% of the time. All three models. About a second each.

The database lookup itself took 0.02 milliseconds.

## What changed

Nothing about the models. Same weights, same settings, same hardware.

What changed is who was making the decision. In the first round, the model had to decide how many devices were implanted. In the second, that decision had already been made by someone with the authority to make it, and the model's only job was to say it clearly.

Those numbers come from Product Performance Reports that Abbott, Boston Scientific, and Medtronic publish every year. My system pulls them into a database. When a question lands, it doesn't reason about implant counts. It looks them up.

Vinh Nguyen has a framing I like for this: behaviors, decisions, execution. Three layers. He was kind enough to put my system, Bulkhead τ, in that picture. When we talked about it, the way I put it back to him was:

"Your PBC captures the decisions. The substrate is the decisions."

His Product Behavior Contracts are for writing a decision down before an agent has to guess it. In my domains, somebody with authority already wrote it down. The job isn't inventing the decision. It's making sure the agent reads it instead of improvising.
https://www.linkedin.com/pulse/behaviors-decisions-execution-three-layers-ai-safe-memory-vinh-nguyen-ryjvc

## The honest part

Here's where I'd love to say the database was perfect. It wasn't.

Building those 247 questions meant going through the data carefully, and my own substrate had zombies in it. About 31% of the device family names had text from the PDFs bled into them, things like "0.00%Accent DR RF." 17.7 million implants were sitting under a family called "Unknown."

None of that came from the manufacturers. It came from my extraction.

So I had to skip the family-level questions where the data was dirty, and every answer in the test is "what my database says," not "what the PDF says." That's a real limit, and I'd rather state it than have someone find it.

It's also exactly Vinh's point from his piece on signing off: anything you extract is only a candidate until a human has reviewed it. A source of truth still needs sign-off.
https://www.linkedin.com/pulse/auto-generated-specs-arent-reliable-until-youve-signed-vinh-nguyen-yrpvc

## Why this matters for "deterministic AI"

This started as a thread about whether deterministic AI would be faster than probabilistic AI. For my kind of work, the answer turned out to be sideways.

The deterministic part is absurdly fast. But the model still has to phrase the answer, so you're back on model time either way. What determinism actually bought was being right.

The model is the interface. The decisions have to live somewhere it can't argue with.
