CALL gds.beta.pipeline.linkPrediction.predict.stream('userMovieGraph', {
    modelName: 'model-embed',
    topN: 2000
})
YIELD node1, node2, probability

WITH gds.util.asNode(node1) AS n1,
     gds.util.asNode(node2) AS n2,
     probability

WITH
CASE WHEN n1:User THEN n1 ELSE n2 END AS u,
CASE WHEN n1:Movie THEN n1 ELSE n2 END AS m,
probability

//filtering out mvoies that the user has already watched:
WHERE u.userId = 64
AND NOT (u)-[:RATED]->(m)

RETURN
u.userId AS User,
m.title AS RecommendedMovie,
probability

ORDER BY probability DESC
LIMIT 10;