import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import precision_recall_curve, auc

# 1. Load Data
ratings = pd.read_csv('../data/ratings.csv')
users   = pd.read_csv('../data/users.csv')
movies  = pd.read_csv('../data/movies.csv', encoding='latin-1')

# 2. Build Positive Samples (observed edges = label 1)
pos = ratings[['user_id', 'movie_id']].copy()
pos['label'] = 1

# 3. Build Negative Samples (unobserved edges = label 0)
observed = set(zip(pos['user_id'], pos['movie_id']))
all_users  = ratings['user_id'].unique()
all_movies = ratings['movie_id'].unique()

rng = np.random.default_rng(42)
neg_rows = []
while len(neg_rows) < len(pos):
    u = rng.choice(all_users)
    m = rng.choice(all_movies)
    if (u, m) not in observed:
        neg_rows.append({'user_id': u, 'movie_id': m, 'label': 0})

neg = pd.DataFrame(neg_rows)

# 4. Genre columns already binary in movies.csv - just select them
genre_cols = ['unknown','Action','Adventure','Animation','Children','Comedy',
              'Crime','Documentary','Drama','Fantasy','FilmNoir','Horror',
              'Musical','Mystery','Romance','SciFi','Thriller','War','Western']

# 5. Combine & Attach ONLY raw attributes (no graph features)
data = (pd.concat([pos, neg], ignore_index=True)
          .merge(users[['user_id', 'age', 'gender']], on='user_id')
          .merge(movies[['movie_id'] + genre_cols], on='movie_id'))

# Encode gender: M=1, F=0
data['gender'] = (data['gender'] == 'M').astype(int)

# 6. Train / Test Split - NO graph features, only age, gender, genres
feature_cols = ['age', 'gender'] + genre_cols

X = data[feature_cols]
y = data['label']

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)

# 7. Train Random Forest
rf = RandomForestClassifier(n_estimators=100, random_state=42, n_jobs=-1)
rf.fit(X_train, y_train)

# 8. Evaluate with AUCPR
y_probs = rf.predict_proba(X_test)[:, 1]
precision, recall, _ = precision_recall_curve(y_test, y_probs)
aupr_score = auc(recall, precision)

print(f"Traditional ML (NO graph features) Test AUCPR: {aupr_score:.4f}")

# 9. Feature Importance
importances = pd.Series(rf.feature_importances_, index=feature_cols).sort_values(ascending=False)
print("\nFeature Importances:")
print(importances)