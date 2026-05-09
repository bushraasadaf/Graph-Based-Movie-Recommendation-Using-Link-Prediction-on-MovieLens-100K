**Project Overview**

This project implements a graph-based movie recommendation system using the Neo4j Graph Data Science (GDS) library.

We formulate movie recommendation as a link prediction problem on a bipartite graph (User–Movie), where the objective is to predict whether a user will interact (rate) a previously unseen movie.

Problem Formulation

Nodes:

User → movie users
Movie → movies in the dataset

Relationships:

(User)-[:RATED {rating, timestamp}]->(Movie)

Task:
Predict missing RATED edges (link prediction)

**Dataset**

We use the MovieLens dataset:
https://files.grouplens.org/datasets/movielens/ml-100k/

users.csv → demographic information (age, gender, occupation)
movies.csv → movie metadata and genre labels
ratings.csv → user–movie interaction ratings
Graph Construction

We derive structural and behavioral node features:

User Degree → number of movies rated (activity level)
Movie Degree → number of ratings received (popularity)
User Avg Rating → user rating behavior (strict vs generous users)
Movie Avg Rating → overall movie quality
Movie Genres Representation

Movie genres are stored as a single string property in the format:
Action|Comedy|Drama

This design choice reduces graph complexity and improves query efficiency by avoiding additional genre nodes.

**Pipeline Overview (Experiments)**

We evaluate multiple feature engineering strategies using Neo4j GDS link prediction pipelines.

**Experiment 1: Degree Only**

Objective:
Evaluate whether simple activity and popularity signals are sufficient for prediction.

Features:

user_degree
movie_degree

Interaction Function (HADAMARD):
Computes element-wise interaction between node features:

user_degree × movie_degree

Model: Logistic Regression

**Experiment 2: Degree + AvgRating**

Objective:
Incorporate user behavior and movie quality into the prediction.

Features:

user_degree
movie_degree
user_avgRating
movie_avgRating

HADAMARD Interaction:

user_degree × movie_degree
user_avgRating × movie_avgRating

Insight:
Captures both:
popularity effects
rating behavior patterns
perceived movie quality

**Experiment 3: Structural Features + Embeddings**

Objective:
Capture higher-order graph structure beyond local features.

Additional Step:

FastRP embeddings (64-dimensional vectors)

Features:

degree
avgRating
embedding

HADAMARD Interaction:
Combines:

structural similarity (embedding × embedding)
activity signals
rating behavior

Why embeddings matter:
They encode:

multi-hop relationships
community structure
latent similarity patterns

**Experiment 4: Embeddings Only**

Objective:
Evaluate pure graph representation learning without handcrafted features.

Features:

embedding only

Models evaluated:

Logistic Regression
Random Forest

**Traditional Machine Learning Baseline**

We implement a non-graph baseline using a content-based recommendation approach.

Problem Formulation

Recommendation is framed as a binary classification task:

1 → user has rated/interacted with a movie
0 → no interaction

Unlike graph-based models, this approach does not utilize user–item connectivity or graph structure.

Features Used
User features: age
Movie features: genre indicators (binary encoding)

These represent a purely content-based feature space without graph signals or embeddings.

**Results Summary**
| Experiment             | Test AUCPR  | 
| ---------------------- | ----------- | 
| Degree Only            |  0.3230     |
| Degree + AvgRating     |  0.3230     |
| Structural + Embedding |  0.3230     |
| Embeddings Only        |  0.8068     |

//random forest:
| Embeddings Only        |  0.901      |
| Traditional ML         |  0.6828     |

**Key Findings**
Simple graph features (degree and average rating) are insufficient for strong prediction performance.
Structural embeddings significantly improve predictive accuracy.
Embeddings capture latent relationships not observable in raw features.
Graph-based representation learning outperforms traditional machine learning baselines.

**Tools & Technologies**
Neo4j Graph Data Science (GDS)
FastRP Embeddings
Logistic Regression
Random Forest (scikit-learn)
Python (Pandas, NumPy)
Cypher Query Language

**Setup Instructions**
1. Neo4j Setup

Install Neo4j Desktop or AuraDB and enable:

dbms.security.allow_csv_import_from_file_urls=true
2. Data Placement

Place CSV files in:

<NEO4J_HOME>/import/
3. Graph Construction

Run:

graph_construction.cypher
4. Run Experiments

Execute Cypher queries in Neo4j Browser or GDS environment.
