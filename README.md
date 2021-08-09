# PhotoSelectionClassifier
This is a sample app to create a photo selection classifier using CreateML on an iOS Device.

## Demo
In the demo video below, we are selecting only hamburger photos and share to album.

As a result, a trained photo selection classifier auto-selects hamburger photos.

(photos quoted from: https://unsplash.com/)

![PhotoSelectionClassifierDemo](https://user-images.githubusercontent.com/8536870/128665017-0629cc59-cf17-4447-afcd-11d8cbbd0303.gif)

## Requirements
- Xcode 13 beta 4
- Swift 5.0+
- iOS 15.0+

### Important
**It can only be built on an actual device equipped with a neural engine of iPhone X or later because of CreateML framework.**

## Sequence Diagram

![image](https://user-images.githubusercontent.com/8536870/128665305-4926e156-feb1-4f4e-95f5-295e8606eec7.png)

## References
- https://developer.apple.com/videos/play/wwdc2021/10037
- https://developer.apple.com/videos/play/wwdc2020/10156
- https://developer.apple.com/documentation/createml/creating_an_image_classifier_model
- https://developer.apple.com/documentation/coreml/core_ml_api/downloading_and_compiling_a_model_on_the_user_s_device
- https://developer.apple.com/documentation/vision/classifying_images_with_vision_and_core_ml
