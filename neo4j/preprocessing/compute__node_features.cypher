//COMPUTE NODE FEATURES
// Compute user degree = number of movies rated by user
// Rationale: captures user ACTIVITY level (active users behave differently)
MATCH (u:User)-[:RATED]->()
WITH u, count(*) AS deg
SET u.degree = deg;


// Compute movie degree = number of users who rated the movie
// Rationale: captures movie POPULARITY (popular movies more likely to be linked)
MATCH ()-[:RATED]->(m:Movie)
WITH m, count(*) AS deg
SET m.degree = deg;

//Compute features of average rating:
// Compute average rating given by each user
//Rationale: captures USER BEHAVIOR (strict vs generous raters)
MATCH (u:User)-[r:RATED]->()
WITH u, avg(r.ratings) AS avgR
SET u.avgRating = avgR;

// Compute average rating received by each movie
// Rationale: captures MOVIE QUALITY / appeal
MATCH ()-[r:RATED]->(m:Movie)
WITH m, avg(r.ratings) AS avgR
SET m.avgRating = avgR;
