//EXPERIMENT 1: DEGREE ONLY
// RATIONALE:
// Baseline model using ONLY graph activity/popularity.
// Tests: "Can simple counts predict links?"

// Project graph into GDS using ONLY degree
CALL gds.graph.project(
'userMovieGraph',
{
User: { properties: ['degree'] },
Movie: { properties: ['degree'] }
},
{ RATED: { orientation: 'UNDIRECTED' } }
)
YIELD graphName, nodeCount, relationshipCount;


// Create link prediction pipeline
CALL gds.beta.pipeline.linkPrediction.create('lp-degree');


// Add HADAMARD feature using degree
// WHAT HADAMARD DOES HERE:
// For a (user, movie) pair;  multiplies:
//     user.degree × movie.degree
// Rationale:
// Captures interaction:
//     active users + popular movies : higher likelihood of link
CALL gds.beta.pipeline.linkPrediction.addFeature('lp-degree', 'HADAMARD', {
nodeProperties: ['degree']
});


// Configure train/test split
// - 80% training, 20% testing
// - Negative sampling creates fake non-edges
CALL gds.beta.pipeline.linkPrediction.configureSplit('lp-degree', {
testFraction: 0.2,
trainFraction: 0.8,
validationFolds: 3,
negativeSamplingRatio: 1.0
});


// Add logistic regression classifier
CALL gds.beta.pipeline.linkPrediction.addLogisticRegression('lp-degree', {
maxEpochs: 100    //The model looks at the data 100 times to adjust its weights ( we chose this value to ensure model has enough iterations to learn the patterns of data)
});


// Train model and evaluate using AUCPR
CALL gds.beta.pipeline.linkPrediction.train('userMovieGraph', {
pipeline: 'lp-degree',
modelName: 'model-degree',
targetRelationshipType: 'RATED',
sourceNodeLabel: 'User',
targetNodeLabel: 'Movie',
//to ensure our results are consistent across all experiments, this value was fixed:
randomSeed: 42,  
metrics: ['AUCPR']
})
YIELD modelInfo
RETURN
'Degree Only' AS Experiment,
modelInfo.metrics.AUCPR.train.avg AS trainAUCPR,
modelInfo.metrics.AUCPR.test AS testAUCPR;

