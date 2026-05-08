CALL gds.beta.pipeline.linkPrediction.predict.stream('userMovieGraph', {
    modelName: 'model-embed',
    topN: 10
})
YIELD node1, node2, probability

WITH gds.util.asNode(node1) AS n1,
     gds.util.asNode(node2) AS n2,
     probability

RETURN
CASE WHEN n1:Movie THEN n1.title ELSE n2.title END AS Movie,
CASE WHEN n1:User THEN n1.userId ELSE n2.userId END AS User,
probability

ORDER BY probability DESC
LIMIT 10;