# harbour-hipsterfish
Hipsterfish is a native Instagram client fot Sailfish OS written in QML and C++.

## Instagram signature key
### Description
In order to be able to build harbour-hipsterfish you have to obtain the Instagram signature key, which is used to sign requests made to the Instagram API.

The signature key changes with every new release of the Instagram app and it is directly tied to the version number in the User-Agent HTTP header.

A short time after a new release is published by Instagram, the old signature key gets invalidated. That means that a user will get an error "Old Version" while trying to log-in, comment, like, and so on...

### How to get the Instagram signature key
To extract the Instagram signature key from the Android app, please have a look here: http://mokhdzanifaeq.github.io/extracting-instagram-signature-key/

If you have a new signature key, **make sure it corrosponds to the correct version in the User-Agent header**.
To get the header you can use an web-debugging proxy like [Charles Proxy](https://www.charlesproxy.com/) or others.

### Add the Instagram signature key to the project
After you have extracted the signature key, add a new file in the project's root-directory named **instagram_signature_key.key** with the signature key in it.
After that the project should build just fine and if everything is ok (correct signature key + correct version number), you should be able to login and make requests to the Instagram API.
