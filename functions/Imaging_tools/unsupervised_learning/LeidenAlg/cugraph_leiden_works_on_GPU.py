#!/usr/bin/env python
import cudf
import cugraph
from cuml.neighbors import NearestNeighbors
import scanpy as sc
import cupy as cp

import logging
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('dataset')
parser.add_argument('--embedding', default='X_scVI_vanilla', type=str)
parser.add_argument('--neighbors', default=50, type=int)
parser.add_argument('--resolution', default=1, type=float)
parser.add_argument('--cluster_col', default='scvi_leiden_cugraph', type=str)
ARGS = parser.parse_args()

logger = logging.getLogger('leiden')
logger.setLevel('INFO')
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
sh = logging.StreamHandler()
sh.setFormatter(formatter)
logger.addHandler(sh)

for k, v in ARGS.__dict__.items():
  logger.info(f'{k}:\t{v}')

logger.info(f'Reading data from {ARGS.dataset}')
ad = sc.read_h5ad(ARGS.dataset)
logger.info(f'Reading embedding from {ARGS.embedding} ')
x = ad.obsm[ARGS.embedding]
logger.info(f'Working on embedding {x.shape}')

X_cudf = cudf.DataFrame(x)

model = NearestNeighbors(n_neighbors=ARGS.neighbors)
model.fit(x)

kn_graph = model.kneighbors_graph(X_cudf)

G = cugraph.Graph()

offsets = cudf.Series(kn_graph.indptr)
indices = cudf.Series(kn_graph.indices)
G.from_cudf_adjlist(offsets, indices, None)

parts, mod_score = cugraph.leiden(G, resolution=ARGS.resolution)
clusters = cp.asnumpy(parts['partition'].values)

cluster_str = [f'{c:02d}' for c in clusters]

logger.info(f'stashing clusters ({len(cluster_str)}) --> {ARGS.cluster_col}')
ad.obs[ARGS.cluster_col] = cluster_str

logger.info(f'saving --> {ARGS.dataset}')
ad.write(ARGS.dataset)

