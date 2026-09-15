# Blinded Release Checklist

## Completed

- [x] One participant-wide deidentified CSV with a stable data dictionary
- [x] Synthetic participant and stimulus identifiers with no released crosswalk
- [x] Exact questionnaire rescoring and trial reconstruction checks
- [x] Two self-contained, numbered, commented R scripts
- [x] Full analysis run from released data only
- [x] Generated tables, figures, diagnostics, and file hashes
- [x] Methods, equations, code guide, data guide, and result crosswalk
- [x] Public-file scan for study-team and organization identifiers
- [x] Public-file scan for unrelated study data and direct linkage identifiers

## Required before external release

- [ ] Confirm that participant-level sharing at the chosen access level is
  permitted by consent, ethics approval, and the data-management plan
- [ ] Replace the named initial Git history with a single anonymous release commit
- [ ] Add permitted AI image files using synthetic stimulus IDs, or explicitly
  state in the submission that images are available through controlled access
- [ ] Choose and add appropriate code and data licences
- [ ] Re-run both R scripts and the anonymity audit after the final Git commit
- [ ] Keep author details, affiliations, acknowledgements, ethics-board identity,
  and a named citation file outside the blinded repository until unblinding
