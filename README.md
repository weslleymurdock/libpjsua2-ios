---
title: libpjsua2
date: '2023-14-10'
description: PJSIP Libraries built with Github Actions 
author: 'Weslley Murdock'
---
 
<!--Introduction -->
I've created this repo to automatize new release builds from [pjsip](https://github.com/pjsip).
The goal was automatize the build for Android,, iOS, OSX, Linux and Windows platforms, also compile external dependencies with each build.
The future plans is upgrade the xamarin solution provided by pjsip to an MAUI app. 
<br>
 
<!-- Your badges -->

### Platforms automated build

- [ ] [![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://github.com/weslleymurdock/libpjsua2/actions/workflows/android.yml)
- [x] [![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white)](https://github.com/weslleymurdock/libpjsua2/actions/workflows/ios.yml)
- [ ] [![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://github.com/weslleymurdock/libpjsua2/actions/workflows/linux.yml)
- [ ] [![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)](https://github.com/weslleymurdock/libpjsua2/actions/workflows/win32.yml)
- [ ] [![OSX](https://img.shields.io/badge/mac%20os-000000?style=for-the-badge&logo=macos&logoColor=F0F0F0)](https://github.com/weslleymurdock/libpjsua2/actions/workflows/osx.yml)

### Libs automated build

- [ ] pjsip [![pjsip](https://img.shields.io/badge/github-%23121011.svg?style=for-the-badge&logo=github&logoColor=white)](https://github.com/pjsip/pjproject)
- [x] OpenSSL for iPhone [![ssl-ios](https://img.shields.io/badge/github-%23121011.svg?style=for-the-badge&logo=github&logoColor=white)](https://github.com/x2on/OpenSSL-for-iPhone)
- [x] openh264 [![openh264](https://img.shields.io/badge/github-%23121011.svg?style=for-the-badge&logo=github&logoColor=white)](https://www.github.com/cisco/openh264)
- [x] opus [![opus](https://img.shields.io/badge/github-%23121011.svg?style=for-the-badge&logo=github&logoColor=white)](https://github.com/xiph/opus/)
- [x] zrtp [![zrtp](https://img.shields.io/badge/github-%23121011.svg?style=for-the-badge&logo=github&logoColor=white)](https://github.com/wernerd/ZRTP4PJ) (currently not in use by ios workflow)

### Remaining TODO


* Workflow for Xamarin app build.
* Port PJSIP Xamarin app to MAUI
 
<!-- Credit -->
### ACKNOWLEDGEMENTS 
- [**VoIPGRID**](https://github.com/VoIPGRID) for scripts that brings me the idea of this work. 