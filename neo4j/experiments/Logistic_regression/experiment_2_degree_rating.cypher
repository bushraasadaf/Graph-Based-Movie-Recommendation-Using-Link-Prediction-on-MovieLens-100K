// EXPERIMENT 2: DEGREE + AVG RATING
// RATIONALE: Adds user behavior to the baseline degree feature and
// tests: "Does user rating style + movie quality improve prediction?"

// Clean previous graph and pipeline
CALL gds.graph.drop('userMovieGraph');
CALL gds.pipeline.drop('lp-degree');


// Re-project graph with additional node features
CALL gds.graph.project(
'userMovieGraph',
{
User: { properties: ['degree', 'avgRating'] },
Movie: { properties: ['degree', 'avgRating'] }
},
{ RATED: { orientation: 'UNDIRECTED' } }
)
YIELD graphName, nodeCount, relationshipCount;


// Create new pipeline
CALL gds.beta.pipeline.linkPrediction.create('lp-degree-rating');


// Add HADAMARD feature using degree + avgRating
// WHAT HADAMARD DOES HERE:
// Produces:
//   user.degree × movie.degree
//   user.avgRating × movie.avgRating
// WHY:
// - Captures BOTH:
//   (activity × popularity)
//   (user behavior × movie quality)
// This Learns interaction patterns instead of treating features independently
CALL gds.beta.pipeline.linkPrediction.addFeature('lp-degree-rating', 'HADAMARD', {
nodeProperties: ['degree', 'avgRating']
});


// Configure split
CALL gds.beta.pipeline.linkPrediction.configureSplit('lp-degree-rating', {
testFraction: 0.2,
trainFraction: 0.8,
validationFolds: 3,
negativeSamplingRatio: 1.0
});


// Add classifier
CALL gds.beta.pipeline.linkPrediction.addLogisticRegression('lp-degree-rating', {
maxEpochs: 100
});


// Train and evaluate
CALL gds.beta.pipeline.linkPrediction.train('userMovieGraph', {
pipeline: 'lp-degree-rating',
modelName: 'model-degree-rating',
targetRelationshipType: 'RATED',
sourceNodeLabel: 'User',
targetNodeLabel: 'Movie',
randomSeed: 42,
metrics: ['AUCPR']
})
YIELD modelInfo
RETURN
'Degree + AvgRating' AS Experiment,
modelInfo.metrics.AUCPR.train.avg AS trainAUCPR,
modelInfo.metrics.AUCPR.test AS testAUCPR;
