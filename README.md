## AWS Elastic Inference TensorFlow Examples

AWS Tensorflow Elastic Inference cost analysis blog post code. Notebook measures the timing of running object detection on a video locally v. Elastic Inference.

Please follow the walkthrough in this [blog](https://aws.amazon.com/blogs/machine-learning/optimizing-costs-in-amazon-elastic-inference-with-amazon-tensorflow/) to run the example. 

Currently, to present the cost and performance benefits of using AWS Elastic Inference with Tensorflow, this repository uses 

1. M5.large instance
2. Large EI accelerator
3. EIPredictor data structure
4. Faster R-CNN ResNet50 frozen model

At the end of the walkthrough, you should see a short video as below:

[![Annotated Dog Park](https://github.com/aws-samples/aws-elastic-inference-tensorflow-examples/blob/master/annotated_dog_park.gif)](https://github.com/aws-samples/aws-elastic-inference-tensorflow-examples/blob/master/annotated_dog_park.gif)

## License Summary

The documentation is made available under the Creative Commons Attribution-ShareAlike 4.0 International License. See the LICENSE file.

The sample code within this documentation is made available under the MIT-0 license. See the LICENSE-SAMPLECODE file.

The Jupyter notebook in artifacts is under Apache-2 license. See the artifacts/LICENSE file.
