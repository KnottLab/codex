import numpy as np
import scanpy as sc
import pandas as pd
from scipy.io import loadmat
from anndata import AnnData



print('loading data in python ...')
a = loadmat('features_for_LeidenAlg.mat')
X = a['X']
print('data loaded:', X.shape)




print('running LeidenAlg ...')
ad = AnnData(X, obs=pd.DataFrame(index=np.arange(X.shape[0])), var=pd.DataFrame(index=np.arange(X.shape[1])))

#sc.pp.pca(ad)

sc.pp.neighbors(ad,method='umap',metric='euclidean')
#sc.pp.neighbors(ad,method='umap', metric='correlation')

sc.tl.leiden(ad, resolution=5, key_added='leiden')
#sc.tl.leiden(ad, resolution=1, key_added='leiden')


idx = ad.obs['leiden'].to_numpy('float')



np.savetxt('tmp_clusters.txt', idx, delimiter=',')




