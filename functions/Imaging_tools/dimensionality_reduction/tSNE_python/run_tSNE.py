import numpy as np
from MulticoreTSNE import MulticoreTSNE as TSNE
from scipy.io import loadmat



a = loadmat('tm_forTSNE_features.mat')
X = a['X']
print('data loaded:', X.shape)

print('running tSNE')
tsne = TSNE(n_jobs=4, learning_rate=200, perplexity=250, n_components=10, verbose=3)

Y = tsne.fit_transform(X)

np.savetxt('tmp_tSNE_coords.txt', Y, delimiter=',')