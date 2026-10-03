# Practicing which method applies

Research notes for issue #73 (map #70, in-app Canvas intake). Question: what does the research say about practicing *which* method, formula, theorem, or test applies, as opposed to always solving fully; what prompt formats train it; what intake must capture per concept; and whether generating these prompts needs a strong cloud model.

Source depth is marked on each citation: **full text** (read the paper), **abstract** (publisher or indexed abstract only), or **book** (*Make It Stick*, read directly).

## Answer in brief

- The skill is real, separate from execution, and blocked practice skips it. In blocked practice "students know the appropriate strategy before they read each problem" [R14]. Interleaving forces the choice, and it produced large gains on delayed tests: d = 1.05 [R14] and d = 0.83 in a preregistered classroom RCT with 787 students [R20]. In undergraduate physics, d = 0.40 to 0.91 [SP21].
- Interleaving helps most when the categories are **confusable**: high similarity between categories and low similarity within them [BR19]. The benefit comes from putting them side by side (discriminative contrast). Spacing *between* interleaved items reduced it [KP12, SYK17].
- Some of the benefit is just pairing the problem with its method, not only telling look-alikes apart. In [R14] almost no errors were wrong-method errors. Instead, blocked practice let students "ignore the features of a problem that indicate which strategy is appropriate." So prompts must make the learner read the problem's features, and the cover story must not give the answer away.
- Formats with evidence: **pick the method** (interleaved, unlabelled problems), **pick and say why** (name the principle) [ARM03], **compare two cases** (d = 0.50 on average) [ANS13; RJS07], **sort by structure, not by story** [QM96, QM02], and **faded worked examples with "which principle is this step?" prompts** [ARM03], which work for novices and should be phased out as expertise grows [KASC03].
- Keep some full solves. When given the right strategy, students executed near ceiling in one study [TR10]. In another, most errors were execution errors (45.9%) [R14]. Choosing and executing are both needed. Choosing is the part normal homework never trains.
- **Intake must capture, per method concept:** observable use-when cues, conditions/assumptions, the *decision group* it competes in, confused-with siblings each with a deciding feature, and at least one cited worked example with steps labelled by principle.
- **Model:** generating valid method-pick items needs a strong cloud model. It has to reason across a whole unit's concepts, and the scenario has to satisfy the target's conditions and break each sibling's. Foundation Models (4,096-token window shared between input and output [TN3193]) can still grade the free-text "why", as it already grades short answers. It should **not** reword these items: a changed story can change the right answer.

## 1. Evidence

### Interleaving trains choosing the method

- *Make It Stick* (ch. 3, "Developing Discrimination Skills"): textbooks block problems by chapter, so on a mixed exam students ask "Which algorithm do I use?" Under blocked practice "you have had no practice on that critical sorting process" (book, pp. 53–54). Geometric-volumes study: blocked practice scored 89% vs 60% during practice, but 20% vs 63% a week later (book, p. 50; [RT07]).
- [TR10] Fourth graders on prism problems: interleaved 77% vs blocked 38% a day later. Error analysis: most blocked-group errors used the formula for *another* kind of problem, and when given the strategy, both groups scored near ceiling (as summarised in [R14], full text).
- [R14] Grade 7, problems that did **not** look alike: 72% vs 38%, d = 1.05, after nine weeks of practice and a two-week delay. Wrong-method errors were only 4.4% of errors, so the authors propose that interleaving also strengthens the link between a kind of problem and its strategy. Example: students who worked 12 slope problems in a row could solve them "without noticing the feature of the problem (the word 'slope')" that signalled the strategy. They define "strategy" broadly: "a theorem, formula, concept, or procedure."
- [R20] Cluster-randomised RCT, 54 classes, 787 students: 61% vs 38% on an unannounced test, d = 0.83. Meets WWC standards without reservations.
- [SP21] Introductory university physics, 8 weeks of homework: interleaved practice improved recall of the relevant equations and correct solutions on surprise tests (d = 0.40, then 0.91). The authors credit "practice in strategy selection—that is, choosing the correct solution for a given problem from a range of possible options."
- [SYK17] **Statistics concepts**: interleaving improved classification of new problems. Adding time between interleaved problems *hurt*, which supports between-concept comparison as the mechanism.

### When interleaving helps and when it does not

- [BR19] meta-analysis (59 studies, 238 effect sizes): overall g = 0.42. Math tasks g = 0.34. Words g = −0.39 (blocking was better). Expository texts were ambiguous. Interleaving helps more when categories are more similar to each other, items within a category are less similar, and the material is more complex. It helps more without spacing or distraction between items [BR19, full text]. The authors hesitate to recommend interleaving for math, but their pool had few math studies and predates [R20] and [SP21].
- [KB08] Kornell & Bjork, painters: interleaving beat blocking for classifying new paintings, yet most learners still *believed* blocking worked better. [SP21] found the same misjudgement among physics students. Implication: make interleaving the default, not opt-in, and expect lower accuracy during the session.
- [KP12] Spacing helps induction only when it does not break up the side-by-side contrast.
- Takeaway for the app: interleave **confusable methods next to each other**. The current session rule ("no two consecutive items from the same unit") spreads items across units. That provides spacing, but it can separate exactly the siblings that should be contrasted. Interleave by method set, not by unit.

### Prompt formats

- **Sort or classify by structure.** Novices group problems by surface features. Experts group them by the principle that solves them [CFG81]. Quilici & Mayer taught college statistics students to sort word problems by test (t-test, chi-square, correlation) instead of cover story. Example sets that vary the story independently of the test increased sorting by structure [QM96, QM02; abstract]. For generation: **vary the surface story across methods, and keep the same story across different methods in some items**.
- **Compare cases.** Comparing two solution methods side by side beat studying them one at a time, for conceptual knowledge, procedural knowledge, and flexibility [RJS07]. Meta-analysis: d = 0.50. Comparison works better when the principle is given *after* the comparison [ANS13; abstract].
- **Faded worked examples plus principle prompts.** Fading alone helps near transfer. Adding prompts to "identify the underlying principle illustrated in each worked-out solution step" gave medium-to-large near *and* far transfer gains with no extra time [ARM03; abstract].
- **Expertise reversal.** Worked examples help novices and stop helping, or even hurt, as knowledge grows [KASC03; abstract]. Faded examples belong early in a concept's life. Pick, set-up, and solve prompts belong later.

## 2. Prompt formats to support

| Format | What the learner does | Evidence | Maps to |
|---|---|---|---|
| **Method pick** | Reads an unlabelled scenario and picks the method (MC from the decision group, or free text) | R14, R20, TR10, SYK17 | `PatternPick` payload as is (`statement`, `options`, `correctIndex`, `answer`, `explanation`), but a **non-coding kind** is needed because `PromptKind.patternPick.isCoding == true` |
| **Pick + why** | Picks the method and names the deciding cue or condition | ARM03 (principle prompts) | `shortAnswer` with `keyPoints` = the deciding cues (existing AI grading works) |
| **Set up, don't solve** | Picks the method, then writes the setup (hypotheses, formula with values plugged in, df), with no arithmetic | R14 (pick + link to strategy), SP21 (equation recall) | Like `FullProblem`'s pick → plan stages without code. Either a new staged kind or `shortAnswer` with key points |
| **Contrast pair** | Two near-identical scenarios that need different methods (or different stories that need the same one): pick for each and name the difference | RJS07, ANS13, QM96 | New kind, or MC/short answer with both scenarios in the statement |
| **Sort** | Puts 4–6 short scenarios into method bins | QM96/QM02, CFG81 | New kind (`Potential`); several MC items in a row get most of the benefit |
| **Faded worked example** | Fills in the missing step(s) of a cited example and names the principle used | ARM03, KASC03 | `shortAnswer`; for new concepts only |
| **Full solve** | Solves end to end | R14 (execution errors dominate), TR10 | Existing kinds; keep in the mix |

Rules for generated items (all from the evidence above):
- The statement must not name the method or use its tell-tale keyword ([R14]'s "slope" example). This can be checked without AI: reject a statement that contains the target's title or aliases.
- Distractors come from the target's **confused-with siblings**, not random concepts. Interleaving works best with similar categories [BR19].
- Method sets add up over the course: a unit-5 item can draw options from units 1–4, just as [R14]'s interleaved assignments drew from earlier lessons.
- The explanation names the deciding cue, and why each sibling fails. The principle comes after the attempt [ANS13].

## 3. What intake must capture per concept

Only for concepts whose kind is a method (formula, theorem, test, procedure, pattern). Definitions and facts don't need it.

1. **Use-when cues.** Features you can *see in a problem*, not the definition. Example: "two groups, different subjects, numeric outcome, σ unknown".
2. **Conditions / assumptions.** Example: "n ≥ 30 or roughly normal; independent samples". Scenarios have to satisfy these on purpose, and contrast items break them on purpose.
3. **Decision group.** The set of methods this one competes with on an exam (e.g. "inference tests for means/proportions"). Pairwise confused-with links are not enough to build MC options and interleave sets; the group is the unit of discrimination.
4. **Confused-with siblings, each with a deciding feature.** Example: "paired t: same subjects measured twice". This is the explanation text and the contrast-pair seed.
5. **At least one cited worked example** with steps labelled by principle (for faded examples, set-up model answers, and grounding).
6. Optional: **aliases / tell-tale keywords** for the leak check, and **what "set up" means** for this method (which quantities to state).

Cues, conditions, and siblings must be **grounded** like everything else (file + page citation, or flagged as gap-fill) under the strict-grounding rule in #70.

## 4. Do these prompts need a strong cloud model?

**Generating them: yes, for the main step.**
- Building decision groups and confused-with links means reasoning over every approved method in a unit or course at once. The on-device model has 4,096 tokens per session, shared between input and output [TN3193]. A course's concept list plus excerpts doesn't fit.
- A valid scenario must meet the target's conditions and break each sibling's (paired vs independent, normality, sample size), without naming the method. A subtly wrong item teaches the wrong discrimination, and that error is invisible during review. This needs a strong model plus a verify pass (a second call checks "which method does this scenario need, and why not each sibling?" without seeing the key).
- It batches well: one call per decision group produces N scenarios, so cost scales with groups, not prompts.

**What Foundation Models can do:**
- Grade the free-text "why" or set-up against key points (same as current short-answer grading).
- Pull use-when cues from a single slide or page *within* one concept, if extraction runs on device. Cross-concept work (siblings, groups) still needs the cloud model.
- **Not** reword method-pick, contrast, or set-up items. Changing the story can change the right method. This matches the current rule that variants are limited to kinds whose answer can't drift (`PromptContent.supportsVariants`).

## 5. What this changes in the map (#70)

- **Session interleaving** (not in the map today): "no two consecutive from the same unit" works against contrast between confusable methods. Method items should be interleaved **within a decision group, close together**, across units. This touches R1/R6.1 interleaving and is a Shape-practice/session concern (#79).
- **Decision group** should be a first-class record or field, not just pairwise confused-with links (#77).
- **Attribution in scheduling:** a method-pick answer involves several concepts. Which one gets the grade? Probably the target; a wrong pick of a sibling may also count against that sibling or flag the pair (#77/#79).
- **Prompt kinds:** a non-coding method-pick (generalise `patternPick`, or add a new kind) plus a set-up-without-solving stage (#79).
- **Ordering by concept maturity:** faded examples while a concept is new, then pick / set-up, with full solves mixed in (expertise reversal). This fits Shape practice (#79).
- **Model routing:** generating method items goes to the cloud provider with a verify pass. Foundation Models variants stay off for these kinds.

## Sources

- [book] P. C. Brown, H. L. Roediger III, M. A. McDaniel, *Make It Stick* (2014), ch. 3 "Mix Up Your Practice". **book**
- [RT07] D. Rohrer & K. Taylor, The shuffling of mathematics problems improves learning, *Instructional Science* 35 (2007), 481–498. **book (cited as the volumes study)**
- [TR10] K. Taylor & D. Rohrer, The effects of interleaved practice, *Applied Cognitive Psychology* 24 (2010), 837–848. https://digitalcommons.usf.edu/psy_facpub/1760/ **abstract + summary in R14**
- [R14] D. Rohrer, R. F. Dedrick, K. Burgess, The benefit of interleaved mathematics practice is not limited to superficially similar kinds of problems, *Psychonomic Bulletin & Review* (2014), doi:10.3758/s13423-014-0588-3. https://www.gwern.net/doc/psychology/spaced-repetition/2014-rohrer.pdf **full text**
- [R20] D. Rohrer, R. F. Dedrick, M. K. Hartwig, C.-N. Cheung, A randomized controlled trial of interleaved mathematics practice, *Journal of Educational Psychology* 112(1) (2020), 40–52. WWC review: https://ies.ed.gov/ncee/wwc/Study/88770 **abstract / WWC**
- [SP21] J. Samani & S. C. Pan, Interleaved practice enhances memory and problem-solving ability in undergraduate physics, *npj Science of Learning* 6 (2021), doi:10.1038/s41539-021-00110-x. https://pmc.ncbi.nlm.nih.gov/articles/PMC8589969/ **full text (summarised)**
- [SYK17] F. Sana, V. X. Yan, J. A. Kim, Study sequence matters for the inductive learning of cognitive concepts, *Journal of Educational Psychology* 109(1) (2017), 84–98. https://experts.mcmaster.ca/scholarly-works/1731615 **abstract**
- [BR19] M. Brunmair & T. Richter, Similarity matters: A meta-analysis of interleaved learning and its moderators, *Psychological Bulletin* 145 (2019), doi:10.1037/bul0000209. https://www.psychologie.uni-wuerzburg.de/fileadmin/06020400/2019/Brunmair_Richter_in_press__2019_META-ANALYSIS_OF_INTERLEAVED_LEARNING.pdf **full text (accepted manuscript)**
- [KB08] N. Kornell & R. A. Bjork, Learning concepts and categories: Is spacing the "enemy of induction"? *Psychological Science* 19(6) (2008), 585–592. https://bjorklab.psych.ucla.edu/wp-content/uploads/sites/13/2016/07/Kornell_Bjork_2008_PsychScience.pdf **abstract + book**
- [KP12] S. H. K. Kang & H. Pashler, Learning painting styles: Spacing is advantageous when it promotes discriminative contrast, *Applied Cognitive Psychology* 26 (2012), 97–103. **as summarised in BR19 and PMC3978334**
- [CFG81] M. T. H. Chi, P. J. Feltovich, R. Glaser, Categorization and representation of physics problems by experts and novices, *Cognitive Science* 5(2) (1981), 121–152. https://apps.dtic.mil/sti/pdfs/ADA100138.pdf **abstract**
- [QM96] J. L. Quilici & R. E. Mayer, Role of examples in how students learn to categorize statistics word problems, *Journal of Educational Psychology* 88(1) (1996), 144–161. **as cited/summarised**
- [QM02] J. L. Quilici & R. E. Mayer, Teaching students to recognize structural similarities between statistics word problems, *Applied Cognitive Psychology* 16 (2002), doi:10.1002/acp.796. **abstract**
- [RJS07] B. Rittle-Johnson & J. R. Star, Does comparing solution methods facilitate conceptual and procedural knowledge? *Journal of Educational Psychology* 99(3) (2007), 561–574. **abstract**
- [ANS13] L. Alfieri, T. J. Nokes-Malach, C. D. Schunn, Learning through case comparisons: A meta-analytic review, *Educational Psychologist* 48(2) (2013), 87–113. https://www.lrdc.pitt.edu/Schunn/papers/ContrastingCasesMeta-AlfieriEtAl2013.pdf **abstract**
- [ARM03] R. K. Atkinson, A. Renkl, M. M. Merrill, Transitioning from studying examples to solving problems: Effects of self-explanation prompts and fading worked-out steps, *Journal of Educational Psychology* 95(4) (2003), 774–783. https://asu.elsevierpure.com/en/publications/transitioning-from-studying-examples-to-solving-problems-effects-/ **abstract**
- [KASC03] S. Kalyuga, P. Ayres, P. Chandler, J. Sweller, The expertise reversal effect, *Educational Psychologist* 38(1) (2003), 23–31. **abstract**
- [TN3193] Apple, TN3193: Managing the on-device foundation model's context window. https://developer.apple.com/documentation/technotes/tn3193-managing-the-on-device-foundation-model-s-context-window **docs (via search summary)**
