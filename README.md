# ZupanCommandRecognition

Clone the project
Build and Run using Xcode

Notes: iOS on device speech recognition is having issues with numbers. Saying multiple numbers like one six two is identified as one hundred and sixty two, etc. In iOS 17 it will be possible to fine tune the language model, however some workarounds are needed right now. For example, saying number before the actual digit, since the word number will be ignored, so saying something like number one number eight number nine is needed. I added unit tests to showcase the rest of the logic.
