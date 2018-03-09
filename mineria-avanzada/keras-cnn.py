#!/usr/bin/env python

from keras.layers import Conv2D, MaxPooling2D, Dense, Reshape, Flatten, Input
from keras.models import Sequential
from keras.utils.np_utils import to_categorical
import numpy as np
from keras.datasets import mnist

def print_shapes(model):
    for layer in model.layers:
        print(layer.output_shape)

#### GRAPH
model = Sequential()

model.add(Reshape((28, 28, 1), input_shape = (28, 28)))
model.add(Conv2D(
    filters = 32
    , kernel_size = (3, 3)
    , padding = "same"
    , activation = "relu"
))
model.add(MaxPooling2D())
model.add(Conv2D(
    filters = 64
    , kernel_size = (3, 3)
    , padding = "same"
    , activation = "relu"
))
model.add(MaxPooling2D())
model.add(Conv2D(
    filters = 128
    , kernel_size = (3, 3)
    , padding = "same"
    , activation = "relu"
))
model.add(Flatten())
model.add(Dense(2048))
model.add(Dense(10, activation = "softmax"))

print_shapes(model)

#### TRAIN
(x_train, y_train), (x_test, y_test) = mnist.load_data()
        
# normalize
x_train = x_train.astype('float32') / 255.
x_test = x_test.astype('float32') / 255.

y_train = to_categorical(y_train, num_classes = 10)
y_test = to_categorical(y_test, num_classes = 10)

print(x_train.shape)
print(y_train.shape)

model.compile("rmsprop", "categorical_crossentropy")
model.fit(
    x_train, y_train,
    batch_size = 256,
    epochs = 2,
    validation_data = (x_test, y_test),
    shuffle = True
)
print(model.evaluate(x_test, y_test))

# no-relu: 0.0801610
# relu:    0.0359974


# -----------------------------
