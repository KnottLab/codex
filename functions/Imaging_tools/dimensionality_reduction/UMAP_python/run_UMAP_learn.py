import umap
import numpy as np
from scipy.io import loadmat



print('loading data in python ...')
a = loadmat('features_for_UMAP.mat')
X = a['X']
print('data loaded:', X.shape)



print('running UMAP ...')
Y = umap.UMAP(n_neighbors=10,min_dist=0.1,n_components=2,metric='euclidean').fit_transform(X)
#Y = umap.UMAP(n_neighbors=100,min_dist=0.1,n_components=2,metric='correlation').fit_transform(X)



print('saving UMAP output...')
np.savetxt('tmp_UMAP_coordinates.txt', Y, delimiter=',')




