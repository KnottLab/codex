import phenograph
import numpy as np
from scipy.io import loadmat



print('loading data in python ...')
a = loadmat('features_for_PhenoGraph.mat')
X = a['X']
print('data loaded:', X.shape)




print('running PhenoGraph ...')
communities, graph, Q = phenograph.cluster(X)


np.savetxt('tmp_clusters.txt', communities, delimiter=',')




