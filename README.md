# Digit-Recognizer

A project to set up a Convolutional Neural Network to recognize hand-written digits, combined with a front-end Android application. The app can be installed using the "Digit Recognizer CNN.apk" (you may have to allow apps from unknown sources), and should work on most modern android devices.

<img src="https://i.imgur.com/pWoJnd7.png " data-canonical-src="https://i.imgur.com/pWoJnd7.png " width="400" />

The CNN is trained on a subset of the MNIST handwritten digit dataset (https://www.kaggle.com/c/digit-recognizer/), with a data augmentation approach to reduce overfitting. The CNN scores a 99.6% test accuracy on Kaggle's holdout test dataset, which is around the expected performance for this sort of approach. For reference, the best possible models (typically ensembled CNNs) score at maximum around 99.7% on the holdout dataset. 

It's architecture consists of:

- Input of a 28x28x1 array of pixel intensities normalized between 0 and 1
- Two 3x3 convolution layers, with 32 filters
- A 5x5 convolution layer, with 32 filters and stride 2
- Dropout layer with rate 0.4
- Two 3x3 convolution layers, with 64 filters
- A 5x5 convolution layer, with 64 filters and stride 2
- Dropout layer with rate 0.4
- A 4x4 convolution layer, with 128 filters
- A dense layer with 256 nodes
- Dropout layer with rate 0.5
- Output

The Android application was created using Google's Flutter UI toolkit in the DART programming language with the model deployed using Tensflow Lite. It consists of a square drawing pad that captures an image of the drawing on every stroke end, which is then downscaled to a 28x28 image and passed to the model. The model then returns it's most likely and second most likely predictions which are then displayed.
