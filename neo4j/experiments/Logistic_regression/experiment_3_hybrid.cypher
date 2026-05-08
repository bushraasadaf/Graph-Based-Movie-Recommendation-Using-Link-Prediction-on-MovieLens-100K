// EXPERIMENT 3: NODE + EMBEDDING FEATURES
// RATIONALE:
// Adds learned graph structure via embeddings.
// Tests: "Does global structure similarity of graph improve performance of local features of degree and avg rating?”

// Reset graph and pipeline
CALL gds.graph.drop('userMovieGraph');
CALL gds.pipeline.drop('lp-degree-rating');


// Re-project graph
CALL gds.graph.project(
'userMovieGraph',
{
User: { properties: ['degree', 'avgRating'] },
Movie: { properties: ['degree', 'avgRating'] }
},
{
RATED: { orientation: 'UNDIRECTED' }
}
)
YIELD graphName, nodeCount, relationshipCount;


// Generate FastRP embeddings
// WHY:
// Encodes multi-hop graph structure into vector form
CALL gds.fastRP.mutate('userMovieGraph', {
embeddingDimension: 64, //length of vector
randomSeed: 42, 
mutateProperty: 'embedding'
});
 
//write to DB (needed for experiment 4)
CALL gds.graph.nodeProperties.write('userMovieGraph', ['embedding']);

// Create pipeline
CALL gds.beta.pipeline.linkPrediction.create('lp-struct');


// Add HADAMARD feature using degree + avgRating + embedding
// WHAT HADAMARD DOES HERE: it multiplies the following features:
 // 1. degree: Multiplies User activity by Movie popularity (user degree x movie degree)
 //2. avgRating: Matches the User's typical score with the Movie's general quality (user avg rating x movie avg rating)
//user_embedding: a mathematical summary of a user's rating history
//movie_embedding: A mathematical summary of what kind of users watch that movie. 
 // 3. embedding: user embedding x movie embedding
//Thus, it combines user + movie representations and node features into one decision. 
CALL gds.beta.pipeline.linkPrediction.addFeature(
'lp-struct',
'HADAMARD',
{
nodeProperties: ['degree', 'avgRating', 'embedding']
}
);


// Configure split
CALL gds.beta.pipeline.linkPrediction.configureSplit(
'lp-struct',
{
testFraction: 0.2,
trainFraction: 0.8,
validationFolds: 3,
negativeSamplingRatio: 1.0
}
);


// Add classifier
CALL gds.beta.pipeline.linkPrediction.addLogisticRegression(
'lp-struct',
{ maxEpochs: 100 }
);


// Train model
CALL gds.beta.pipeline.linkPrediction.train('userMovieGraph', {
pipeline: 'lp-struct',
modelName: 'model-struct',
targetRelationshipType: 'RATED',
sourceNodeLabel: 'User',
targetNodeLabel: 'Movie',
randomSeed: 42,
metrics: ['AUCPR']
})
YIELD modelInfo
RETURN
'Structural + Node + Embedding' AS Experiment,
modelInfo.metrics.AUCPR.train.avg  AS trainAUCPR,
modelInfo.metrics.AUCPR.test AS testAUCPR;
