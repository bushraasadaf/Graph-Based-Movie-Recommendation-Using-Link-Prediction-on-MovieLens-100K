// GRAPH MODEL RATIONALE
//
// Nodes:
// - User: represents a user in MovieLens dataset
// - Movie: represents a movie 
//
// Relationships:
// - (User)-[:RATED {rating, timestamp}]->(Movie)
//
// Properties:
// - Movie.genres: stored as a string separated by ‘|’ (e.g. Action|Comedy|Drama)
//
// Design Choice:
// - Genres are stored as a property instead of separate nodes
// to reduce graph complexity and keep query performance efficient.
// - Ratings are modeled as relationships to enable graph analytics
// such as similarity, centrality, and recommendation potential.
//
// Goal of this model:
// - Support user-movie interaction analysis
// - Enable recommendation and similarity computations
// - Allow graph statistics and analytics such as popularity in movie trends, user engagement, and rating distributions


// STEP 1: CREATING CONSTRAINTS
// Constraints are going to ensure uniqueness and improve performance
// This prevents duplicate nodes and speeds up MERGE operations:

CREATE CONSTRAINT user_id IF NOT EXISTS FOR (u:User) REQUIRE u.userId IS UNIQUE;


CREATE CONSTRAINT movie_id IF NOT EXISTS FOR (m:Movie) REQUIRE m.movieId IS UNIQUE;


// STEP 2: LOAD USERS
// We create User nodes with basic attributes such as age,
// gender, and occupation
LOAD CSV WITH HEADERS FROM 'file:///users.csv' AS row
FIELDTERMINATOR ','


MERGE (u:User {userId: toInteger(row.user_id)})
SET u.age = toInteger(row.age),
u.gender = row.gender,
u.occupation = row.occupation;


// STEP 3: LOADING MOVIE NODES
LOAD CSV WITH HEADERS FROM 'file:///movies.csv' AS row
FIELDTERMINATOR ','


// Adding genre as a property from the csv file, multiple genres are separated by ‘|’
WITH row,
CASE WHEN row.Action = "1" THEN "Action|" ELSE "" END +
CASE WHEN row.Adventure = "1" THEN "Adventure|" ELSE "" END +
CASE WHEN row.Animation = "1" THEN "Animation|" ELSE "" END +
CASE WHEN row.Children = "1" THEN "Children|" ELSE "" END +
CASE WHEN row.Comedy = "1" THEN "Comedy|" ELSE "" END +
CASE WHEN row.Crime = "1" THEN "Crime|" ELSE "" END +
CASE WHEN row.Documentary = "1" THEN "Documentary|" ELSE "" END +
CASE WHEN row.Drama = "1" THEN "Drama|" ELSE "" END +
CASE WHEN row.Fantasy = "1" THEN "Fantasy|" ELSE "" END +
CASE WHEN row.FilmNoir = "1" THEN "Film-Noir|" ELSE "" END +
CASE WHEN row.Horror = "1" THEN "Horror|" ELSE "" END +
CASE WHEN row.Musical = "1" THEN "Musical|" ELSE "" END +
CASE WHEN row.Mystery = "1" THEN "Mystery|" ELSE "" END +
CASE WHEN row.Romance = "1" THEN "Romance|" ELSE "" END +
CASE WHEN row.SciFi = "1" THEN "Sci-Fi|" ELSE "" END +
CASE WHEN row.Thriller = "1" THEN "Thriller|" ELSE "" END +
CASE WHEN row.War = "1" THEN "War|" ELSE "" END +
CASE WHEN row.Western = "1" THEN "Western|" ELSE "" END
AS combinedGenres

// removing the last ‘|’
WITH row,
CASE
WHEN size(combinedGenres) > 0 THEN LEFT(combinedGenres, size(combinedGenres) - 1)
ELSE ""
END AS genresCleaned


// Create Movie nodes
MERGE (m:Movie {movieId: toInteger(row.movie_id)})
SET m.title = row.movie_title,
m.releaseDate = row.release_date,
m.videoReleaseDate = row.video_release_date,
m.imdbUrl = row.imdb_url,
m.genres = genresCleaned;


// Step 4: Loading Ratings and connecting Users to Movies
// Load the CSV file containing user-movie ratings
LOAD CSV WITH HEADERS FROM 'file:///ratings.csv' AS row
FIELDTERMINATOR ','


// Creating relationships between User and Movie nodes
MATCH (u:User {userId: toInteger(row.user_id)})
MATCH (m:Movie {movieId: toInteger(row.movie_id)})
MERGE (u)-[r:RATED]->(m)
SET r.ratings = toInteger(row.ratings),
r.timestamp = toInteger(row.timestamp);