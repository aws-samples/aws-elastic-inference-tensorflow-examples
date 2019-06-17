#!/bin/bash

docker build . -t aws-tf1.13-ei1.1-video-object-detection 

docker run -it --rm -p 8888:8888 aws-tf1.13-ei1.1-video-object-detection
