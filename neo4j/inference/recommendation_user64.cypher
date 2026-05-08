//Recommendation:
CALL gds.beta.pipeline.linkPrediction.predict.stream('userMovieGraph', {
    modelName: 'model-embed',
    topN: 2000
})
YIELD node1, node2, probability
WITH gds.util.asNode(node1) AS n1,
     gds.util.asNode(node2) AS n2,
     probability
WHERE n1.userId = 64 OR n2.userId = 64
RETURN
    CASE WHEN n1.userId = 64 THEN n1.userId ELSE n2.userId END AS User,
    CASE WHEN n1.title IS NOT NULL THEN n1.title ELSE n2.title END AS RecommendedMovie,
    probability
ORDER BY probability DESC
LIMIT 10;

