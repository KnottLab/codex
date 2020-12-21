from time import time
import numpy as np
import keras.backend as K
from keras.engine.topology import Layer, InputSpec
from keras.models import Model
from keras.utils.vis_utils import plot_model
from sklearn.cluster import KMeans
from ConvAE import CAE
from datasets import load_from_mat
from keras.callbacks import CSVLogger
import csv, os
import argparse
import os
import matplotlib.pyplot as plt






class ClusteringLayer(Layer):
    def __init__(self, n_clusters, weights=None, alpha=1.0, **kwargs):
        if 'input_shape' not in kwargs and 'input_dim' in kwargs:
            kwargs['input_shape'] = (kwargs.pop('input_dim'),)
        super(ClusteringLayer, self).__init__(**kwargs)
        self.n_clusters = n_clusters
        self.alpha = alpha
        self.initial_weights = weights
        self.input_spec = InputSpec(ndim=2)

    def build(self, input_shape):
        assert len(input_shape) == 2
        input_dim = input_shape[1]
        self.input_spec = InputSpec(dtype=K.floatx(), shape=(None, input_dim))
        self.clusters = self.add_weight(shape=(self.n_clusters, input_dim), initializer='glorot_uniform', name='clusters')
        if self.initial_weights is not None:
            self.set_weights(self.initial_weights)
            del self.initial_weights
        self.built = True

    def call(self, inputs, **kwargs): # Probability of zi belonging to cluster j 
        q = 1.0 / (1.0 + (K.sum(K.square(K.expand_dims(inputs, axis=1) - self.clusters), axis=2) / self.alpha))
        q **= (self.alpha + 1.0) / 2.0
        q = K.transpose(K.transpose(q) / K.sum(q, axis=1))
        return q

    def compute_output_shape(self, input_shape):
        assert input_shape and len(input_shape) == 2
        return input_shape[0], self.n_clusters

    def get_config(self):
        config = {'n_clusters': self.n_clusters}
        base_config = super(ClusteringLayer, self).get_config()
        return dict(list(base_config.items()) + list(config.items()))











class DCEC(object):
    def __init__(self,
                 input_shape,
                 filters=[32, 64, 128, 10],
                 n_clusters=10,
                 alpha=1.0):
        super(DCEC, self).__init__()
        self.n_clusters = n_clusters
        self.input_shape = input_shape
        self.alpha = alpha
        self.pretrained = False
        self.y_pred = []

        self.cae = CAE(input_shape, filters)
        hidden = self.cae.get_layer(name='embedding').output

        self.encoder = Model(inputs=self.cae.input, outputs=hidden)

        clustering_layer = ClusteringLayer(self.n_clusters, name='clustering')(hidden)
        self.model = Model(inputs=self.cae.input,outputs=[clustering_layer, self.cae.output])




    def pretrain(self, x, batch_size=256, epochs=200, optimizer='adam', save_dir='results/temp'):
        print('Number of epochs: ',epochs)
        print('batch size: ',batch_size)
        csv_logger = CSVLogger(args.save_dir + '/pretrain_log.csv')
        self.cae.compile(optimizer=optimizer, loss='mse')
        self.cae.fit(x, x, batch_size=batch_size, epochs=epochs, callbacks=[csv_logger], verbose=2)
        self.cae.save(save_dir + '/pretrained_cae_model.h5')
        self.pretrained = True

    def load_weights(self, weights_path):
        self.model.load_weights(weights_path)

    def extract_feature(self, x):  # extract features from before clustering layer
        return self.encoder.predict(x)

    def predict(self, x):
        q, _ = self.model.predict(x, verbose=0)
        return q.argmax(1)

    @staticmethod
    def target_distribution(q):
        weight = q ** 2 / q.sum(0)
        return (weight.T / weight.sum(1)).T

    def compile(self, loss=['kld', 'mse'], loss_weights=[1, 1], optimizer='adam'):
        self.model.compile(loss=loss, loss_weights=loss_weights, optimizer=optimizer)

    def fit(self, x, y=None, batch_size=256, epochs=200,maxiter=150, tol=1e-3,
            cae_weights=None, save_dir='./results/temp'):


        # Step 1: pretrain if necessary 
        if not self.pretrained and cae_weights is None:
            print('\n*****  Fitting CAE (Pretraining)  *****\n')
            t1 = time()
            self.pretrain(x, batch_size, epochs, save_dir=save_dir)
            print('Pretraining time: ', time() - t1)
        elif cae_weights is not None:
            print('\n*****  Loading CAE weights  *****\n')
            self.cae.load_weights(cae_weights)
            print('\nCAE weights loaded\n')


        # Step 2: initialize cluster centers using k-means
        print('\n*****  Initializing cluster centroids with k-means  ( k =',self.n_clusters,')  *****\n')
        t2 = time()
        kmeans = KMeans(n_clusters=self.n_clusters, n_init=20)
        self.y_pred = kmeans.fit_predict(self.encoder.predict(x))
        y_pred_last = np.copy(self.y_pred)
        self.model.get_layer(name='clustering').set_weights([kmeans.cluster_centers_])
        print('K-means Clustering time:', time() - t2)


        # Step 3: deep clustering
        print('\n*****  Deep Clustering  *****\n')
        t3 = time()
        loss = [0, 0, 0]
        index = 0
        delta_label = 0
        with open(save_dir + '/deep_clustering_log.txt', 'w') as file:
            file.write('iter delta_label loss clustering_loss deconv1_loss nbr_clusters\n')
        #maxiter = 0
        for ite in range(int(maxiter)):


            #print(self.model.get_layer(name='clustering').get_weights())

            # update deep_clustering_log
            with open(save_dir + '/deep_clustering_log.txt', 'a') as file:
                file.write(str(ite)+' '+str(delta_label)+' '+str(loss[0])+' '+str(loss[1])+' '+str(loss[2])+' '+str(len(np.unique(self.y_pred)))+'\n')
            print('iter: ',ite,'/',maxiter,'  |  delta_label: ',delta_label,'  | loss: ',loss,'  | nbr clusters: ',len(np.unique(self.y_pred)))


            # Predict new labels
            q, _ = self.model.predict(x, batch_size=batch_size, verbose=0)
            self.y_pred = q.argmax(1)
            #self.y_pred = kmeans.fit_predict(q)

            #print('iter: ',ite,'/',maxiter,'  |  delta_label: ',delta_label,'  | loss: ',loss,'  | nbr clusters: ',len(np.unique(self.y_pred)))
            #plt.plot(self.y_pred)
            #plt.show()


            # check stop criterion
            delta_label = np.sum(self.y_pred != y_pred_last).astype(np.float32) / self.y_pred.shape[0]
            y_pred_last = np.copy(self.y_pred)
            if ite > 0 and delta_label < tol:  
                print('delta_label ', delta_label, '< tol ', tol)
                print('Reached tolerance threshold at iteration ',iter,'. Stopping training.')
                break


            # train on batch
            #batch_idx = np.floor(np.random.uniform(0,x.shape[0],batch_size)).astype('int')
            batch_idx = range(index * batch_size, min([(index + 1)*batch_size, x.shape[0]]))
            if (index + 1) * batch_size > x.shape[0]:
                index = 0
            else:
                index += 1

            p = self.target_distribution(q)  # update the auxiliary target distribution p
            #loss = self.model.train_on_batch(x = x[batch_idx], y=[p[batch_idx],x[batch_idx]])
            loss = self.model.train_on_batch(x = x, y=[p,x])



            # save intermediate model
            #if ite % save_interval == 0:
            #print('saving model to:', save_dir + '/dcec_model_' + str(ite) + '.h5')
            #self.model.save_weights(save_dir + '/dcec_model_' + str(ite) + '.h5')

        # save the trained model
        #print('saving model to:', save_dir + '/dcec_model_final.h5')
        #self.model.save(save_dir + '/dcec_model_final.h5')
        print('Clustering time:', time() - t3)


        #q, _ = self.model.predict(x, batch_size=batch_size, verbose=1)
        #self.y_pred = kmeans.fit_predict(q)
        
        
        
        








if __name__ == "__main__":

    # setting the hyper parameters
    print('\n################  DCEC  ################\n')
    parser = argparse.ArgumentParser(description='train')
    parser.add_argument('--n_clusters', default=10, type=int)
    parser.add_argument('--n_features', default=10, type=int)
    parser.add_argument('--batch_size', default=256, type=int)
    parser.add_argument('--epochs', default=100, type=int)
    parser.add_argument('--maxiter', default=150, type=int)
    parser.add_argument('--gamma', default=0.5, type=float, help='coefficient of clustering loss')
    parser.add_argument('--tol', default=0.00000000000001, type=float)
    parser.add_argument('--cae_weights', default=None, help='This argument must be given')
    parser.add_argument('--save_dir', default='outputs/3_DCEC')
    parser.add_argument('--input_mat_file', default='you_need_it')
    args = parser.parse_args()
    
    print('\n################  args  ################')
    print(args)
    if not os.path.exists(args.save_dir):
        os.makedirs(args.save_dir)


    print('\n################  Data Loading  ################')
    x = load_from_mat(args.input_mat_file)


    print('\n################  Initializing DCEC model  ################\n')
    dcec = DCEC(input_shape=x.shape[1:], filters=[32, 64, 128, args.n_features], n_clusters=args.n_clusters)
    print('\n**  DCEC model  summary**\n')
    dcec.model.summary()
    plot_model(dcec.model, to_file=args.save_dir + '/dcec_model.png', show_shapes=True)
    print('\n**  CAE model  summary**\n')
    dcec.cae.summary()
    plot_model(dcec.cae, to_file=args.save_dir + '/cae_model.png', show_shapes=True)
    print('\n################  DCEC model initialized  ################\n')


    print('\n################  Compiling DCEC  ################')
    dcec.compile(loss=['kld', 'mse'], loss_weights=[args.gamma, 1], optimizer='adam')


    print('\n################  Fitting DCEC  ################\n')
    dcec.fit(x, y=None, tol=args.tol, maxiter=args.maxiter, batch_size=args.batch_size, epochs=args.epochs,
             save_dir=args.save_dir, cae_weights=args.cae_weights)
    print('\n################  Fitting DCEC done ################\n')


    print('\n################  Export results  ################\n')
    y_pred = dcec.y_pred
    np.savetxt(args.save_dir + '/clusters.txt', y_pred, delimiter=',')

    features = dcec.encoder.predict(x)
    print('feature shape =', features.shape)
    np.savetxt(args.save_dir + '/features.txt', features, delimiter=',')
    print('\n################  All done  ################\n')






