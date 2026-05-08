//We repeated the embeddings only experiment with "random_forest" model 
//to evaluate more acuurate performance results:

//Random forest:
// STEP 1: Clean up
CALL gds.graph.drop('userMovieGraph');
CALL gds.model.drop('model-embed');
CALL gds.pipeline.drop('lp-embed');

// STEP 2: Re-project with embeddings
CALL gds.graph.project(
    'userMovieGraph',
    {
        User:  { properties: ['degree', 'avgRating', 'embedding'] },
        Movie: { properties: ['degree', 'avgRating', 'embedding'] }
    },
    { RATED: { orientation: 'UNDIRECTED' } }
);

// STEP 3: Create pipeline
CALL gds.beta.pipeline.linkPrediction.create('lp-embed');

// STEP 4: Add feature
CALL gds.beta.pipeline.linkPrediction.addFeature(
    'lp-embed', 'HADAMARD',
    { nodeProperties: ['embedding'] }
);

// STEP 5: Configure split
CALL gds.beta.pipeline.linkPrediction.configureSplit('lp-embed', {
    testFraction: 0.2,
    trainFraction: 0.8,
    validationFolds: 3,
    negativeSamplingRatio: 1.0
});

// STEP 6: Add Random Forest instead of logistic regression
CALL gds.beta.pipeline.linkPrediction.addRandomForest('lp-embed', {
    numberOfDecisionTrees: 10
});

// STEP 7: Train
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
RETURN modelInfo.metrics.AUCPR.test AS testAUCPR;