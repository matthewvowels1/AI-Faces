# Stimulus Materials

## Established photographs

The FACES photographs are not redistributed in this repository. They should be
obtained and used under the terms of the original FACES database and publication.
The collection access page is <https://faces.mpdl.mpg.de/imeji/collections?q=>.
The released `stimulus_manifest.csv` assigns each analysed photograph a synthetic
ID and retains only the coded attributes needed to reproduce the statistics.

## AI-generated photographs

AI face images were generated with the GPT-4o image-generation model in August
2025. For variants intended to preserve an identity, the previously generated
image was supplied as a visual reference and the prompt requested that identity
and background be kept as similar as possible. Prompts varied age, gender, skin
description, hair description, and target emotion using the following template:

> Generate me a similarly composed image of a face portrait in a neutral
> environment (e.g. blank white wall behind the face) for a [age] [gender] with
> [skin description] and [hair description] displaying a [emotion] emotion on
> their face. Same aspect ratio.

The identities were not independently validated as sufficiently matched across
emotion or demographic variants. This limits claims that observed differences
are caused by source, diversity, or emotion alone.

The task-interface figure and an AI-only example montage are included in
`manuscript_figures/`. The complete set of 161 individual image files is not
present in the source archive from which this review package was assembled.
Before a final materials release, the deidentified AI images should be added
under `stimuli/ai/` using the synthetic IDs in `data/stimulus_manifest.csv`, after
confirming that their release is permitted. Their absence does not prevent
reproduction of the reported analyses because all trial-to-stimulus links and
analysed stimulus attributes are in the CSV files.

## Sampling procedure

For each of 80 trials, the task sampled source uniformly from the available
sources, sampled emotion uniformly from the emotions available within that
source, and sampled an unused image from that source-emotion pool. A pool was
reset only after all images in it had been used. The complete sequence was
generated before presentation. `task/stimulus_sampling.mjs` is an isolated,
platform-neutral reference implementation of this procedure.
