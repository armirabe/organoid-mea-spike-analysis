# Publishing this repository

Delete this file before your first push — it is instructions for you, not
documentation for users.

## Before anything goes public

1. **Get your PI's sign-off in writing.** The paper being published does not
   automatically make the analysis code releasable. Ask specifically about
   the CNT array, since a patent filing would change the answer.
2. **Confirm the license.** MIT is the usual choice for academic analysis
   code. Your university may have a policy; NC State's Office of Research
   Commercialization can confirm.
3. **Check the legacy scripts for anything sensitive.** They are committed
   as-is. The hard-coded filenames (`Class I gsk.xlsx`, `AAV Spontaneous.xlsx`)
   and sheet names (`cluster 2 glut001`, `9007`) encode experimental
   conditions and sample identifiers. Ask whether those should stay.

## Fill in the placeholders

- `LICENSE` — replace `REPLACE_WITH_YOUR_NAME` and check the year
- `CITATION.cff` — replace the two `REPLACE_WITH_*` author fields, and add
  your co-authors if the lab wants the full list
- `README.md` — add yourself and the other authors to the citation line if
  you'd rather not use "et al."

## Publish

Install git and the GitHub CLI, then from this directory:

```bash
git init
git add .
git commit -m "Spike detection and analysis pipeline for organoid MEA recordings"
git branch -M main
```

With the GitHub CLI:

```bash
gh auth login
gh repo create organoid-mea-spike-analysis --public --source=. --push
```

Or create an empty repository at github.com/new (no README, no license,
no .gitignore — this repo already has them), then:

```bash
git remote add origin https://github.com/YOUR_USERNAME/organoid-mea-spike-analysis.git
git push -u origin main
```

## After the first push

1. **Run `run_demo` and commit a figure.** A README with one raster or
   waveform image is far more convincing than one without. Save it to
   `docs/` and reference it from the README — `results/` is gitignored.
2. **Add repository topics** on GitHub: `electrophysiology`,
   `spike-detection`, `matlab`, `organoids`, `mea`. This is how people find
   it, and it signals the domain to anyone skimming your profile.
3. **Set the description** to one line, e.g. "MATLAB spike detection and
   analysis for cerebral organoid recordings on CNT microelectrode arrays."
4. **Link the paper** in the repository's About sidebar.
5. **Pin it to your profile** so it is the first thing a reviewer sees.

## Then update your resume

Add the GitHub URL to your header next to LinkedIn. Nothing else needs to
change — the Neural Data Processing Pipeline entry already describes this
work.

## A caution about the untested code

`src/` has not been run. Execute `run_demo` before you make the repository
public, and fix whatever it surfaces. A repository whose demo throws on the
first invocation is worse than no repository at all, and this is the single
highest-risk item on the list.
