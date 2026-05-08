// EXPERIMENT 4: EMBEDDINGS ONLY
// RATIONALE:
// Tests pure graph representation learning.
// Removes features of degree and avg rating entirely.

// Remove previous model
CALL gds.model.drop("model-struct");


// Create new pipeline
CALL gds.beta.pipeline.linkPrediction.create('lp-embed');


// Add HADAMARD using embeddings ONLY
// WHAT HADAMARD DOES HERE:
// Computes element-wise product:
//user_embedding: a mathematical summary of a user's rating history
//movie_embedding: A mathematical summary of what kind of users watch that movie. 
//  result: user_embedding x movie_embedding

// WHY:
// Captures similarity + compatibility between nodes and gives a single "relationship" vector that tells the model how well the user and movie match up
CALL gds.beta.pipeline.linkPrediction.addFeature(
'lp-embed',
'HADAMARD',
{ nodeProperties: ['embedding'] }
);


// Configure split
CALL gds.beta.pipeline.linkPrediction.configureSplit(
'lp-embed',
{
testFraction: 0.2,
trainFraction: 0.8,
validationFolds: 3,
negativeSamplingRatio: 1.0
}
);


// Add classifier
CALL gds.beta.pipeline.linkPrediction.addLogisticRegression(
'lp-embed',
{ maxEpochs: 100 }
);


// Train model
CALL gds.beta.pipeline.linkPrediction.train('userMovieGraph', {
pipeline: 'lp-embed',
modelName: 'model-embed',
targetRelationshipType: 'RATED',
sourceNodeLabel: 'User',
targetNodeLabel: 'Movie',
randomSeed: 42,
metrics: ['AUCPR']
})
YIELD modelInfo
RETURN
'Embeddings Only' AS Experiment,
modelInfo.metrics.AUCPR.train.avg AS trainAUCPR,
modelInfo.metrics.AUCPR.test AS testAUCPR;

