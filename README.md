---
title: libpjsua2
date: '2023-14-10'
description: PJSIP Libraries built with Github Actions 
author: 'Weslley Murdock'
---
 
<!--Introduction -->
I've created this repo to automatize new release builds from [pjsip](https://github.com/pjsip) for iOS
\s\s
An android version is available [here](https://github.com/weslleymurdock/libpjsua2-android)
<!-- Your badges -->

### Platforms automated build

- [x] [![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white)](https://github.com/weslleymurdock/libpjsua2/actions/workflows/ios.yml)

|      ABI      | SSL   | OPUS  | H264 | BCG729 |
|---------------|-------|-------|------|--------|
|    armv7      |   X   |   X   |   X  |    X   |
|    armv7s     |   X   |   X   |   X  |    X   |
|    arm64      |   -   |   -   |   -  |    -   |
|    i386       |   X   |   X   |   X  |    X   |
|    x86_64     |   -   |   -   |   -  |    -   |

**NOTE**: 1 - Given an gui alert in config_site, for now the build for i386 arch is disabled. Maybe its need a workaround in the ./configure to skip this validation just on this arch

### Libs with automated build

- [x] pjsip [![pjsip](https://img.shields.io/badge/github-%23121011.svg?style=for-the-badge&logo=github&logoColor=white)](https://github.com/pjsip/pjproject)
- [x] OpenSSL for iPhone [![ssl-ios](https://img.shields.io/badge/github-%23121011.svg?style=for-the-badge&logo=github&logoColor=white)](https://github.com/x2on/OpenSSL-for-iPhone)
- [x] openh264 [![openh264](https://img.shields.io/badge/github-%23121011.svg?style=for-the-badge&logo=github&logoColor=white)](https://www.github.com/cisco/openh264)
- [x] opus [![opus](https://img.shields.io/badge/github-%23121011.svg?style=for-the-badge&logo=github&logoColor=white)](https://github.com/xiph/opus/)
- [x] bcg729 [![bcg729](https://img.shields.io/badge/github-%23121011.svg?style=for-the-badge&logo=github&logoColor=white)](https://github.com/BelledonneCommunications/bcg729)
- [x] zrtp [![zrtp](https://img.shields.io/badge/github-%23121011.svg?style=for-the-badge&logo=github&logoColor=white)](https://github.com/wernerd/ZRTP4PJ) (currently not in use by ios workflow)

### Remaining TODO
 
- [x] Port PJSIP Xamarin app to MAUI (Added on PR to pjsip repository samples) 

### ACKNOWLEDGEMENTS

- [**VoIPGRID**](https://github.com/VoIPGRID) for scripts that brings me the idea of this work.
