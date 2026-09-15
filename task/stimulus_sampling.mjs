/*
 * Platform-neutral reference implementation of the study's stimulus sampling.
 *
 * Input rows must contain:
 *   source         "FACES" or "AI"
 *   filename_emotion emotion label parsed from the original stimulus filename
 *   stimulus_id    synthetic stimulus identifier
 *
 * The original task used Math.random(), so no seeded sequence is recoverable.
 */

export function groupStimuli(stimulusRows) {
  const pools = {};

  for (const stimulus of stimulusRows) {
    if (!pools[stimulus.source]) pools[stimulus.source] = {};
    if (!pools[stimulus.source][stimulus.filename_emotion]) {
      pools[stimulus.source][stimulus.filename_emotion] = [];
    }
    pools[stimulus.source][stimulus.filename_emotion].push(stimulus.stimulus_id);
  }

  return pools;
}

function chooseUniformly(values, randomNumber) {
  if (values.length === 0) throw new Error("Cannot sample an empty set");
  return values[Math.floor(randomNumber() * values.length)];
}

function availableSources(stimulusPools) {
  return Object.keys(stimulusPools).filter(
    source => Object.keys(stimulusPools[source]).length > 0
  );
}

function availableEmotions(stimulusPools, source) {
  return Object.keys(stimulusPools[source]).filter(
    emotion => stimulusPools[source][emotion].length > 0
  );
}

function chooseImage(stimulusPools, usedImages, source, emotion, randomNumber) {
  const completePool = stimulusPools[source][emotion];
  const poolKey = `${source}::${emotion}`;

  if (!usedImages[poolKey]) usedImages[poolKey] = new Set();
  if (usedImages[poolKey].size >= completePool.length) {
    usedImages[poolKey].clear();
  }

  const unusedImages = completePool.filter(
    stimulusId => !usedImages[poolKey].has(stimulusId)
  );
  const stimulusId = chooseUniformly(unusedImages, randomNumber);
  usedImages[poolKey].add(stimulusId);
  return stimulusId;
}

export function generateTrialSequence(
  stimulusRows,
  numberOfTrials = 80,
  randomNumber = Math.random
) {
  const stimulusPools = groupStimuli(stimulusRows);
  const sources = availableSources(stimulusPools);
  const usedImages = {};
  const trials = [];

  for (let trialNumber = 1; trialNumber <= numberOfTrials; trialNumber += 1) {
    const source = chooseUniformly(sources, randomNumber);
    const emotions = availableEmotions(stimulusPools, source);
    const targetEmotion = chooseUniformly(emotions, randomNumber);
    const stimulusId = chooseImage(
      stimulusPools,
      usedImages,
      source,
      targetEmotion,
      randomNumber
    );

    trials.push({
      trial_number: trialNumber,
      source,
      target_emotion: targetEmotion,
      stimulus_id: stimulusId
    });
  }

  return trials;
}
